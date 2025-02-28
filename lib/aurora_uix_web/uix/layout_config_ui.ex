defmodule AuroraUixWeb.Uix.LayoutConfigUI do
  @moduledoc ~S"""
  The AuroraUixWeb.Uix.LayoutConfigUI defines how the fields are going to be rendered.

  ## Examples

    ```elixir
    defmodule ProductViews do
      alias MyApp.Inventory
      alias MyApp.Inventory.Product

      auix_resource_config(:product, context: Inventory, schema: Product)

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

      auix_resource_config(:product, context: Inventory, schema: Product)

      auix_create_ui do
        index :product, [:reference, :name]
        layout :product do
          inline [:reference, :name, :description]
        end
      end
    end
    ```
    In the index only the columns reference and name will be shown, while the form should contain
    only the indicated three fields.

    Only one index should be used.
    More than one `inline` commands can be used, each of them represents a different line in the form view.

    ```elixir
    defmodule ProductViews do
      alias MyApp.Inventory
      alias MyApp.Inventory.Product

      auix_resource_config(:product, context: Inventory, schema: Product)

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

    Fields UI characteristics can be overridden with keyword options.

    ```elixir
    defmodule ProductViews do
      alias MyApp.Inventory
      alias MyApp.Inventory.Product

      auix_resource_config(:product, context: Inventory, schema: Product)

      auix_create_ui do
        index :product, [:reference, name: [renderer: &upcase_text/1]]
        layout :product do
          inline [id: [hidden: true], reference: [readonly: true, length: 30], description: [length: 255]]
        end
      end
    end
    ```

    Fields can be framed within a named group.

    ```elixir
    defmodule ProductViews do
      alias MyApp.Inventory
      alias MyApp.Inventory.Product

      auix_resource_config(:product, context: Inventory, schema: Product)

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

      auix_resource_config(:product, context: Inventory, schema: Product)

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

      auix_resource_config(:product, context: Inventory, schema: Product)

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

      auix_resource_config(:product, context: Inventory, schema: Product)

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

      auix_resource_config(:product, context: Inventory, schema: Product)

      auix_create_ui do
        layout :product do

          section "Details" do
            inline do
              inline [id: [hidden: true]]
              group "Identification" do
                inline [reference: [readonly: true]]
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

      auix_resource_config(:product, context: Inventory, schema: Product)

      auix_create_ui do
        layout :product do
          inline do
            fields [:quantity_initial, :quantity_entries, quantity_exits, quantity_at_hand], scale: 0
          end
        end
      end
    ```

  """

  alias AuroraUixWeb.Uix.LayoutConfigUI

  @doc false
  defmacro __using__(_opts) do
    quote do
      import AuroraUixWeb.Uix.LayoutConfigUI
      import AuroraUixWeb.Uix.LayoutConfigUI.Inline

      Module.register_attribute(__MODULE__, :_auix_layout_contents, accumulate: true)
      Module.register_attribute(__MODULE__, :_auix_layout_opts, accumulate: true)

      @before_compile AuroraUixWeb.Uix.LayoutConfigUI
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    opts =
      env.module
      |> Module.get_attribute(:_auix_layout_opts)
      |> Map.new()

    env.module
    |> Module.get_attribute(:_auix_layout_contents, [])
    |> List.flatten()
    |> Enum.reduce(
      %{},
      fn {layout, contents}, acc ->
        current = Map.get(acc, layout, [])
        Map.put(acc, layout, [contents | current])
      end
    )
    |> Enum.map(fn {layout, [content]} ->
      {layout, %{layout: content, opts: Map.get(opts, layout, [])}}
    end)
    |> then(&Module.put_attribute(env.module, :_auix_form_layouts, &1))

    :ok
  end

  @doc """
  Defines a layout for a given resource.

  This macro is used within `auix_create_ui` to structure the UI layout of a resource.

  ## Parameters
  - `name` (atom): The name of the UI configuration to apply the layout to.
  - `opts` (keyword): Additional options for configure the layout.
  - `block`: A `do` block containing the layout definition.

  ## Example
  ```elixir
    layout :product do
      inline [:reference, :name, :description]
    end
  ```
  """
  @spec layout(atom, Keyword.t(), Keyword.t() | nil) :: Macro.t()
  defmacro layout(name, opts, do: block) do
    options =
      quote do
        LayoutConfigUI.__layout_options__(
          __MODULE__,
          unquote(name),
          unquote(opts)
        )
      end

    do_block =
      quote do
        __MODULE__
        |> LayoutConfigUI.__extract_config_fields__(unquote(name))
        |> then(&Module.put_attribute(__MODULE__, :_auix_current_fields, &1))

        unquote(block)
      end

    container =
      quote do
        __MODULE__
        |> Module.get_attribute(:_auix_current_container, [])
        |> then(&Module.put_attribute(__MODULE__, :_auix_layout_contents, {unquote(name), &1}))

        Module.delete_attribute(__MODULE__, :_auix_current_container)
      end

    quote do
      import LayoutConfigUI

      unquote(options)
      unquote(do_block)
      unquote(container)
    end
  end

  defmacro layout(name, opts) do
    options =
      quote do
        LayoutConfigUI.__layout_options__(
          __MODULE__,
          unquote(name),
          unquote(opts)
        )
      end

    quote do
      import LayoutConfigUI
      unquote(options)
    end
  end

  @doc """
  Generates a default layout configuration for the given schema configs.

  This function creates an index and form layout based on the fields present
  in the schema configuration.

  ## Parameters
  - `resource_configs` (map): A map where keys are schema names and values are configuration maps.

  ## Returns
  - A tuple containing the updated schema configurations.

  ## Example

  ```elixir
    generate_form_layouts([], %{product: %{fields: [:name, :price]}})
  ```
  """
  @spec generate_form_layouts(list, map) :: list
  def generate_form_layouts(resource_configs, form_layouts) do
    resource_configs
    |> extract_config_field_names()
    |> do_generate_form_layouts(resource_configs, form_layouts)
  end

  @doc false
  @spec __layout_options__(module, atom, Keyword.t()) :: :ok
  def __layout_options__(module, name, opts) do
    Module.put_attribute(module, :_auix_layout_opts, {name, opts})
  end

  @spec __expand_fields__(module, list) :: list
  def __expand_fields__(module, fields) do
    module
    |> Module.get_attribute(:_auix_current_fields, %{})
    |> expand_fields(fields)
  end

  @spec __extract_config_fields__(module, atom) :: map
  def __extract_config_fields__(module, name) do
    module
    |> Module.get_attribute(:_auix_resource_configs)
    |> Enum.filter(fn
      {^name, _} -> true
      _ -> false
    end)
    |> Enum.map(fn {_name, config} -> config.fields end)
    |> List.flatten()
    |> Enum.map(&{&1.field, &1})
    |> Map.new()
  end

  ## PRIVATE
  @spec extract_config_field_names(list) :: map
  defp extract_config_field_names(resource_configs) do
    resource_configs
    |> Enum.map(&extract_field_names/1)
    |> Map.new()
  end

  @spec extract_field_names(tuple) :: tuple
  defp extract_field_names({element, %{fields: fields}}) do
    {element, Enum.map(fields, & &1.field)}
  end

  @spec expand_fields(map, Keyword.t()) :: list
  defp expand_fields(current_fields, fields) do
    Enum.map(fields, &Map.get(current_fields, &1))
  end

  @spec do_generate_form_layouts(map, list, map | nil) :: list
  defp do_generate_form_layouts(fields, resource_configs, form_layouts),
    do: Enum.map(resource_configs, &generate_form_layout(&1, fields, form_layouts))

  @spec generate_form_layout(tuple, map, list) :: tuple
  defp generate_form_layout({data_name, resource_config}, fields, form_layouts) do
    form_layout = form_layouts[data_name][:layout]

    fields
    |> Map.get(data_name, [])
    |> then(&Map.merge(resource_config, %{form_layout: form_layout || &1}))
    |> then(&{data_name, &1})
  end
end
