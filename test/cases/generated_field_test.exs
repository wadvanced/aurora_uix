defmodule Aurora.Uix.Test.Cases.GeneratedFieldTest do
  use ExUnit.Case, async: true

  alias Spark.Error.DslError

  @spec compile(binary()) :: module()
  defp compile(field_options) do
    name =
      Module.concat(
        Aurora.UixWeb.Test,
        "GeneratedFieldSample#{System.unique_integer([:positive])}"
      )

    Code.compile_string("""
    defmodule #{inspect(name)} do
      use Aurora.Uix

      auix_resource_metadata :product do
        context Aurora.Uix.Guides.Inventory
        schema Aurora.Uix.Guides.Inventory.Product
        field :name, #{field_options}
      end

      auix_create_ui do
        index_columns :product, [:reference, :name]
      end
    end
    """)

    name
  end

  test "a field declared generated? is loaded with the entity" do
    assert :name in compile("generated?: true").auix_preloads().product
  end

  test "a field not declared generated? is not" do
    refute :name in compile("label: \"Name\"").auix_preloads().product
  end

  test "generated? must be a boolean" do
    assert_raise DslError, ~r/generated\?/, fn -> compile("generated?: \"yes\"") end
  end

  test "data no longer accepts generated" do
    assert_raise DslError, ~r/unknown options \[:generated\]/, fn ->
      compile("data: %{generated: true}")
    end
  end
end
