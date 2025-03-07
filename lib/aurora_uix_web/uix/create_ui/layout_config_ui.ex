defmodule AuroraUixWeb.Uix.CreateUI.LayoutConfigUI do
  @moduledoc ~S"""
  The AuroraUixWeb.Uix.CreateUI.LayoutConfigUI defines how the fields are going to be rendered.

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

  ## Layout Path Structure
    The structure of a layout is represented by a map list where each entry contains the following keys:
    - `:tag` (atom): The command that is being processed. For example: inline, stacked, group, etc.
    - `:state` (atom): The path state, can be :start or :end.
    - `:opts` (keyword): The options for the command, might be empty ([]).
    - `:config` (map | atom): Specific configuration for the command (not an option).
        For example the `layout` command requires the name of the resource_config, that value will be registered
        in the `:config` key. The `group` tag/command will store its title in the `:config` key.

  """

  alias AuroraUixWeb.Uix

  @doc false
  defmacro __using__(_opts) do
    quote do
      import AuroraUixWeb.Uix.CreateUI.LayoutConfigUI
      Module.register_attribute(__MODULE__, :_auix_layout_paths, accumulate: true)
    end
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
  @spec layout(atom, Keyword.t(), any) :: Macro.t()
  defmacro layout(name, opts, do_block \\ nil) do
    register_layout_path(:layout, {:name, name}, opts, do_block)
  end

  @spec inline(Keyword.t(), any) :: Macro.t()
  defmacro inline(fields, do_block \\ nil) do
    {block, fields} = Uix.extract_block_options(fields, do_block)
    register_layout_path(:inline, {:fields, fields}, [], block)
  end

  @spec stacked(Keyword.t(), any) :: Macro.t()
  defmacro stacked(fields, do_block \\ nil) do
    {block, fields} = Uix.extract_block_options(fields, do_block)
    register_layout_path(:stacked, {:fields, fields}, [], block)
  end

  @spec group(atom, Keyword.t(), any) :: Macro.t()
  defmacro group(title, opts, do_block \\ nil) do
    register_layout_path(:group, {:title, title}, opts, do_block)
  end

  @doc """
  Generates a default path structure for rendering UI components based on the given mode.

  This function constructs a list of tagged maps representing UI elements such as `:layout`, `:index`, and `:inline`.
  It generates a default path when no paths are provided, depending on the specified mode (`:index`, `:form`, or `:show`).

  ## Parameters

  - `paths` (`list`) - An existing list of paths. If empty, default paths are generated.
  - `resource_config_name` (`binary`) - The name of the resource configuration.
  - `parsed_opts` (`map`) - A map containing parsed options, including:
    - `:fields` (`list`) - A list of field structures.
  - `mode` (`atom`) - The rendering mode (`:index`, `:form`, or `:show`).

  ## Returns

  - `list` - A list of tagged maps representing the UI structure.

  ## Modes and Behavior

  - **`:index` mode**: Generates an `:index` structure using all available fields as columns.
  - **`:form` and `:show` modes**: Generates a `:layout` structure containing an `:inline` group with all fields.
  - If paths are already provided, they are returned unchanged.

  ## Example

    iex> AuroraUixWeb.Uix.CreateUI.LayoutConfigUI.generate_default_paths([], "product", %{fields: [%{field: :name}, %{field: :price}]}, :index)
    [
      %{tag: :index, state: :start, opts: [], config: {:fields, [:name, :price]}},
      %{tag: :index, state: :end}
    ]

    iex> generate_default_paths([], "product", %{fields: [%{field: :name}, %{field: :price}]}, :form)
    [
      %{tag: :layout, state: :start, config: {:name, "product"}, opts: []},
      %{tag: :inline, state: :start, config: {:fields, [:name, :price]}, opts: []},
      %{tag: :inline, state: :end},
      %{tag: :layout, state: :end}
    ]
  """
  @spec generate_default_paths(list, atom, map, atom) :: list
  def generate_default_paths([], _resource_config_name, %{fields: fields} = _parsed_opts, :index) do
    columns = Enum.map(fields, & &1.field)

    [
      %{tag: :index, state: :start, opts: [], config: {:fields, columns}},
      %{tag: :index, state: :end}
    ]
  end

  def generate_default_paths([], resource_config_name, %{fields: fields} = _parsed_opts, mode)
      when mode in [:form, :show] do
    inline = Enum.map(fields, & &1.field)

    [
      %{tag: :layout, state: :start, config: {:name, resource_config_name}, opts: []},
      %{tag: :inline, state: :start, config: {:fields, inline}, opts: []},
      %{tag: :inline, state: :end},
      %{tag: :layout, state: :end}
    ]
  end

  def generate_default_paths(paths, _resource_config_name, _parsed_opts, _mode), do: paths

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

  @spec register_layout_path(atom, tuple, keyword, any) :: Macro.t()
  defp register_layout_path(tag, config, opts, do_block) do
    {block, opts} = Uix.extract_block_options(opts, do_block)

    registration =
      quote do
        Module.put_attribute(
          __MODULE__,
          :_auix_layout_paths,
          %{tag: unquote(tag), state: :start, opts: unquote(opts), config: unquote(config)}
        )

        unquote(block)
        Module.put_attribute(__MODULE__, :_auix_layout_paths, %{tag: unquote(tag), state: :end})
      end

    quote do
      unquote(registration)
    end
  end
end
