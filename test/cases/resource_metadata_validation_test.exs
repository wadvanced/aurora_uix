defmodule Aurora.Uix.Test.Cases.ResourceMetadataValidationTest do
  use ExUnit.Case, async: true

  alias Spark.Error.DslError

  @spec compile(binary()) :: [{module(), binary()}]
  defp compile(body) do
    Code.compile_string("""
    defmodule Aurora.Uix.Test.Cases.ResourceMetadataValidationTest.Sample#{System.unique_integer([:positive])} do
      use Aurora.Uix

    #{body}
    end
    """)
  end

  test "an unknown field option fails compilation" do
    error =
      assert_raise DslError, fn ->
        compile("""
          auix_resource_metadata :product do
            schema Aurora.Uix.Guides.Inventory.Product
            context Aurora.Uix.Guides.Inventory
            field :name, lable: "Name"
          end
        """)
      end

    assert Exception.message(error) =~ "unknown options [:lable]"
  end

  test "a mistyped resource option fails compilation" do
    assert_raise DslError, ~r/renderers/, fn ->
      compile("""
        auix_resource_metadata :product,
          schema: Aurora.Uix.Guides.Inventory.Product,
          context: Aurora.Uix.Guides.Inventory,
          renderers: :toggle_switch
      """)
    end
  end

  test "a context resource without :context fails compilation" do
    assert_raise DslError, ~r/requires the `:context` option/, fn ->
      compile("""
        auix_resource_metadata :product, schema: Aurora.Uix.Guides.Inventory.Product
      """)
    end
  end

  test "backend options are validated by the backend" do
    assert_raise DslError, ~r/unknown options \[:ash_actor_assign\]/, fn ->
      compile("""
        auix_resource_metadata :product,
          schema: Aurora.Uix.Guides.Inventory.Product,
          context: Aurora.Uix.Guides.Inventory,
          backend_opts: [ash_actor_assign: :current_user]
      """)
    end
  end
end
