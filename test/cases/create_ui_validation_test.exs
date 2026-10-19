defmodule Aurora.Uix.Test.Cases.CreateUIValidationTest do
  use ExUnit.Case, async: true

  alias Aurora.Uix.Layout.Node
  alias Spark.Error.DslError

  @spec compile(binary()) :: [{module(), binary()}]
  defp compile(body) do
    Code.compile_string("""
    defmodule Aurora.UixWeb.Test.CreateUIValidationSample#{System.unique_integer([:positive])} do
      use Aurora.Uix

      auix_resource_metadata :product,
        context: Aurora.Uix.Guides.Inventory,
        schema: Aurora.Uix.Guides.Inventory.Product

    #{body}
    end
    """)
  end

  test "an unknown layout option fails compilation" do
    assert_raise DslError, ~r/unknown index layout options \[:page_tittle\]/, fn ->
      compile("""
        auix_create_ui do
          index_columns :product, [:reference], page_tittle: "Products"
        end
      """)
    end
  end

  test "an unknown field option fails compilation" do
    assert_raise DslError, ~r/field :name: unknown options \[:lable\]/, fn ->
      compile("""
        auix_create_ui do
          edit_layout :product do
            inline [:reference, name: [lable: "Name"]]
          end
        end
      """)
    end
  end

  test "a layout for an undeclared resource fails compilation" do
    assert_raise DslError, ~r/unknown resource :category/, fn ->
      compile("""
        auix_create_ui do
          index_columns :category, [:name]
        end
      """)
    end
  end

  test "a field the resource does not have fails compilation" do
    assert_raise DslError, ~r/unknown fields \[:nmae\] for resource :product/, fn ->
      compile("""
        auix_create_ui do
          edit_layout :product do
            group "Identification", [:reference, :nmae]
          end
        end
      """)
    end
  end

  test "two layouts of the same type for a resource fail compilation" do
    assert_raise DslError, ~r/:product has more than one form layout/, fn ->
      compile("""
        auix_create_ui do
          edit_layout :product do
            inline [:reference]
          end

          edit_layout :product do
            inline [:name]
          end
        end
      """)
    end
  end

  test "a section outside sections fails compilation" do
    assert_raise DslError, ~r/section can only be placed inside sections/, fn ->
      compile("""
        auix_create_ui do
          edit_layout :product do
            section "Prices", [:msrp]
          end
        end
      """)
    end
  end

  test "field places one field, with options or as an association path, in a block" do
    modules =
      compile("""
        auix_create_ui do
          edit_layout :product do
            inline do
              field :reference, readonly: true
              field {:product_location_id, :name}
            end
          end
        end
      """)

    {module, _binary} =
      Enum.find(modules, fn {module, _binary} -> function_exported?(module, :auix_layouts, 0) end)

    assert [%Node.Form{children: [%Node.Inline{children: [reference, location]}]}] =
             module.auix_layouts()

    assert %Node.Field{key: :reference, overrides: %{readonly: true}} = reference
    assert %Node.Field{key: :product_location_id, path: [:name]} = location
  end
end
