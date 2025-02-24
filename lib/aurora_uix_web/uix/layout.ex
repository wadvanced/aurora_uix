defmodule AuroraUixWeb.Uix.Layout do
  @moduledoc ~S"""
  The AuroraUixWeb.Uix.Layout defines how the fields are going to be rendered.

  ## Examples

    ```elixir
    defmodule ProductViews do
      alias MyApp.Inventory
      alias MyApp.Inventory.Product

      auix_schema_config(:product, context: Inventory, schema: Product)

      auix_create_ui
    end
    ```
    This is the most basic way of using the UI.
    By default, the `auix_create_ui` macro will create an inline layout with all the enabled fields for the form,
    and for the index a column (:col) for each of the fields in the order they were defined.

    With layout, you can change which fields are rendered and how they are rendered by indicating a built-in renderer
    or a custom one.

    ```elixir
    defmodule ProductViews do
      alias MyApp.Inventory
      alias MyApp.Inventory.Product

      auix_schema_config(:product, context: Inventory, schema: Product)

      auix_create_ui do
        index [:reference, :name]
        layout :product do
          inline [:reference, :name, :description]
        end
      end
    end
    ```
    In the index only the columns reference and name will be shown, while the form should contain
    only the indicated three fields.

    More than one `inline` commands can be used, each of them represents a different line in the form view.

    ```elixir
    defmodule ProductViews do
      alias MyApp.Inventory
      alias MyApp.Inventory.Product

      auix_schema_config(:product, context: Inventory, schema: Product)

      auix_create_ui do
        layout :product do
          inline [:reference, :name, :description]
          inline [:quantity_initial, :quantity_entries, quantity_exits, quantity_at_hand]
          inline [:height, :width, :length]
        end
      end
    end
    ```

    Keep in mind that the rendering is governed by the media size constraints,
    for instance if the above layout is rendered in a mobile device, each field will be rendered one per line.

    You can use a `do` block to describe the inline fields. In this way, fields UI characteristics can be overridden.
    ```elixir
    defmodule ProductViews do
      alias MyApp.Inventory
      alias MyApp.Inventory.Product

      auix_schema_config(:product, context: Inventory, schema: Product)

      auix_create_ui do
        layout :product do
          inline do
            field :id, hidden: true
            field :reference, readonly: true
            field :name, length: 20
            field :description
          end
        end
      end
    end
    ```

    Fields can be framed within a named group.

    ```elixir
    defmodule ProductViews do
      alias MyApp.Inventory
      alias MyApp.Inventory.Product

      auix_schema_config(:product, context: Inventory, schema: Product)

      auix_create_ui do
        layout :product do
          group "Identification", [:reference, :name, :description]
          group "Quantities", [:quantity_initial, :quantity_entries, quantity_exits, quantity_at_hand]
          group "Dimensions", [:height, :width, :length]
        end
      end
    end
    ```

    The groups can also be inlined:

    ```elixir
    defmodule ProductViews do
      alias MyApp.Inventory
      alias MyApp.Inventory.Product

      auix_schema_config(:product, context: Inventory, schema: Product)

      auix_create_ui do
        layout :product do
          inline do
            group "Identification", [:reference, :name, :description]
            group "Quantities", [:quantity_initial, :quantity_entries, quantity_exits, quantity_at_hand]
          end

          group "Dimensions", [:height, :width, :length]

        end
      end
    end
    ```

    Sections, another way of grouping fields, are intended to behave as tabs, meaning that there can only be
    one shown at each time.

    ```elixir
    defmodule ProductViews do
      alias MyApp.Inventory
      alias MyApp.Inventory.Product

      auix_schema_config(:product, context: Inventory, schema: Product)

      auix_create_ui do
        layout :product do
          inline do
            group "Identification", [:reference, :name, :description]
            group "Quantities", [:quantity_initial, :quantity_entries, quantity_exits, quantity_at_hand]
          end

          group "Dimensions", [:height, :width, :length]

          section "Prices", [:msrp, :rrp, :list_price]
          section "Images", [:image, :thumbnail]
        end
      end
    end
    ```

    The fields list can be defined within a block, so that their UI characteristics can be modified.
    You can also mix groups and inline inside a section.
    ```elixir
    defmodule ProductViews do
      alias MyApp.Inventory
      alias MyApp.Inventory.Product

      auix_schema_config(:product, context: Inventory, schema: Product)

      auix_create_ui do
        layout :product do

          section "Details" do
            inline do
              group "Identification", [:reference, :name, :description]
              group "Quantities", [:quantity_initial, :quantity_entries, quantity_exits, quantity_at_hand]
            end

            group "Dimensions", [:height, :width, :length]
          end

          section "Prices", [:msrp, :rrp, :list_price]
          section "Images", [:image, :thumbnail]
        end
      end
    ```

    Layout can be more complex, by combining sections, groups, inline and field UI overrides.
    ```elixir
    defmodule ProductViews do
      alias MyApp.Inventory
      alias MyApp.Inventory.Product

      auix_schema_config(:product, context: Inventory, schema: Product)

      auix_create_ui do
        layout :product do

          section "Details" do
            inline do
              field :id, hidden: true
              group "Identification" do
                inline do
                  field :reference, readonly: true
                end
                inline [:name, :description]
              end
              group "Quantities", [:quantity_initial, :quantity_entries, quantity_exits, quantity_at_hand]
            end

            group "Dimensions", [:height, :width, :length]
          end

          section "Prices", [:msrp, :rrp, :list_price]
          section "Images", [:image, :thumbnail]
        end
      end
    ```

    The list of fields can be re-defined with the `fields` command

    ```elixir
    defmodule ProductViews do
      alias MyApp.Inventory
      alias MyApp.Inventory.Product

      auix_schema_config(:product, context: Inventory, schema: Product)

      auix_create_ui do
        layout :product do
          inline do
            fields [:quantity_initial, :quantity_entries, quantity_exits, quantity_at_hand], scale: 0
          end
        end
      end
    ```

  """

  @doc """
    Defines a layout for a given name and type.

    This macro is used to define a layout block within a module. It delegates
    to `Layout.__auix_layout__/4` to handle the actual layout generation.

    ## Parameters
    - `name`: The name of the UI configuration to apply the layout to.
    - `opts`: A keyword list of options for the layout.
    - `block`: A `do` block containing the layout definition.

  """
  @spec layout(atom, Keyword.t(), Keyword.t() | nil) :: Macro.t()
  defmacro layout(_name, _opts), do: :ok

  defmacro layout(name, opts, do: block) do
    quote do
      import Layout

      Layout.__auix_layout__(
        __MODULE__,
        unquote(name),
        unquote(opts)
      )

      unquote(block)
    end
  end

  @doc false
  @spec __auix_layout__(module, atom, Keyword.t()) :: :ok
  def __auix_layout__(_module, _name, _opts) do
    :ok
  end
end
