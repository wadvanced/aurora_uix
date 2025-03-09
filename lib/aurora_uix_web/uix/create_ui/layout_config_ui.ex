defmodule AuroraUixWeb.Uix.CreateUI.LayoutConfigUI do
  @moduledoc ~S"""
  Provides macros and helper functions to define how resource fields are rendered in the UI.

  There are **three major layout container types**:

  1. **Index:**
     Used for index views to arrange fields horizontally as columns.
     **Note:** The index layout container requires a `:name` (the resource configuration name) to identify the container.

  2. **Form:**
     Used for editing resources. A form layout container (which also requires a `:name`) starts with a base inline arrangement of fields but can be further customized using additional sub-layout commands.

  3. **Show:**
     Used for displaying resource details. Like the form layout, the show layout container (requiring a `:name`) renders fields in a disabled or read-only state.

  Within the **form** and **show** layout containers, you can further structure the layout using the following sub-layout commands (which do not require the `:name` key):

  - **stacked:**
    Arranges fields vertically in a stacked manner.

  - **group:**
    Groups a set of fields under a common title, allowing you to visually segment related fields.

  - **inline (sub-layout):**
    In addition to the major inline container for index views, an inline block can be used as a sub-layout in form or show containers to horizontally group fields.

  - **section:**
    Organizes fields into tab-like sections where only one section is visible at a time. Each section acts as a distinct tab, making it easier to segregate and focus on different groups of fields.

  ## Layout Path Structure

  Internally, each layout is represented by a list of maps (called “paths”), where each entry contains the following keys:

  - **`:tag` (atom):**
    The layout command. Possible values include:
      - Container commands: `:index`, `:form`, `:show`
      - Sub-layout commands: `:stacked`, `:group`, `:inline`, and `:section`

  - **`:name` (atom):**
    For container layouts (`:index`, `:form`, and `:show`), this key is **required** and holds the resource configuration name to which the layout applies.
    For sub-layout commands, this key is not required.

  - **`:state` (atom):**
    Indicates the beginning (`:start`) or ending (`:end`) of a layout block.

  - **`:opts` (keyword list):**
    Contains additional options for customizing the layout (for example, UI overrides such as field length or custom renderers).

  - **`:config` (tuple or map):**
    Holds specific configuration data:
      - For field lists: `{:fields, fields}` where `fields` is a list of field identifiers.
      - For groups: `{:title, "Group Title"}`.
      - For sections: `{:title, "Section Title"}` or other configuration as needed.
      - Other commands may store custom configuration information here.

  ## Usage Examples

  ### Basic Usage
  The simplest usage creates an index layout for listing resources and a default form layout containing all enabled fields:

    ```elixir
    defmodule ProductViews do
      alias MyApp.Inventory
      alias MyApp.Inventory.Product

      auix_resource_config(:product, context: Inventory, schema: Product)

      auix_create_ui
    end
    ```

  ### Custom Layout for Index and Form
  Customize the index view to display only selected columns, and define a form layout with an inline group of fields:
    ```elixir
    defmodule ProductViews do
      alias MyApp.Inventory
      alias MyApp.Inventory.Product

      auix_resource_config(:product, context: Inventory, schema: Product)

      auix_create_ui do
        index_columns :product, [:reference, :name]
        edit_layout :product do
          inline [:reference, :name, :description]
        end
      end
    end
    ```

  ### Using Sub-Layouts in Form and Show
  Within form and show containers, structure the UI using sub-layout commands such as stacked, group, and inline:

    ```elixir
    defmodule ProductViews do
      alias MyApp.Inventory
      alias MyApp.Inventory.Product

      auix_resource_config(:product, context: Inventory, schema: Product)

      auix_create_ui do
        edit_layout :product do
          inline do
            group "Identification", [:reference, :name, :description]
            stacked [:quantity_initial, :quantity_entries, :quantity_exits, :quantity_at_hand]
          end
          group "Dimensions", [:height, :width, :length]
        end

        show_layout :product do
          inline [:reference, :name, :description]
        end
      end
    end
    ```

  ### Using Section Layouts
  Divide the form or show layout into distinct tabs using sections. Each section represents a tab where only its fields are visible when selected:

    ```elixir
    defmodule ProductViews do
      alias MyApp.Inventory
      alias MyApp.Inventory.Product

      auix_resource_config(:product, context: Inventory, schema: Product)

      auix_create_ui do
        edit_layout :product do
          section "Details", [:reference, :name, :description]
          section "Prices", [:msrp, :rrp, :list_price]
          section "Images", [:image, :thumbnail]
        end
      end
    end
    ```

  ### Overriding Field Options

  Customize UI characteristics for specific fields by supplying keyword options:

    ```elixir
    defmodule ProductViews do
      alias MyApp.Inventory
      alias MyApp.Inventory.Product

      auix_resource_config(:product, context: Inventory, schema: Product)

      auix_create_ui do
        index_columns :product, [:reference, name: [renderer: &upcase_text/1]]
        edit_layout :product do
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
        edit_layout :product do
          group "Identification", [:reference, :name, :description]
          group "Quantities", [:quantity_initial, :quantity_entries, quantity_exits, quantity_at_hand]
          group "Dimensions", [:height, :width, :length]
        end
      end
    end
    ```

    ### Complex Layouts

    Layout can be more complex, by combining sections, groups, inline and field UI overrides.

    ```elixir
    defmodule ProductViews do
      alias MyApp.Inventory
      alias MyApp.Inventory.Product

      auix_resource_config(:product, context: Inventory, schema: Product)

      auix_create_ui do
        edit_layout :product do
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
  Defines a layout for edition form.

  This macro is used within `auix_create_ui` to structure the UI layout for edition of a resource.

  ## Parameters
  - `name` (atom): The name of the UI configuration to apply the layout to.
  - `opts` (keyword): Additional options for configure the layout.
  - `block`: A `do` block containing the layout definition.

  ## Example
  ```elixir
    edit_layout :product do
      inline [:reference, :name, :description]
    end
  ```
  """
  @spec edit_layout(atom, Keyword.t(), any) :: Macro.t()
  defmacro edit_layout(name, opts, do_block \\ nil) do
    register_layout_path_entry(:form, name, nil, opts, do_block)
  end

  @doc """
  Defines a layout for show.

  This macro is used within `auix_create_ui` to structure the UI layout for display a resource.
  A show layout definition overrides the default layout that is taken from the form with all fields disabled.

  ## Parameters
  - `name` (atom): The name of the UI configuration to apply the layout to.
  - `opts` (keyword): Additional options for configure the layout.
  - `block`: A `do` block containing the layout definition.

  ## Example
  ```elixir
    show_layout :product do
      inline [:reference, :name, :description]
    end
  ```
  """
  @spec show_layout(atom, Keyword.t(), any) :: Macro.t()
  defmacro show_layout(name, opts, do_block \\ nil) do
    register_layout_path_entry(:show, name, nil, opts, do_block)
  end

  @spec inline(Keyword.t(), any) :: Macro.t()
  defmacro inline(fields, do_block \\ nil) do
    {block, fields} = Uix.extract_block_options(fields, do_block)
    register_layout_path_entry(:inline, nil, {:fields, fields}, [], block)
  end

  @spec stacked(Keyword.t(), any) :: Macro.t()
  defmacro stacked(fields, do_block \\ nil) do
    {block, fields} = Uix.extract_block_options(fields, do_block)
    register_layout_path_entry(:stacked, nil, {:fields, fields}, [], block)
  end

  @spec group(atom, Keyword.t(), any) :: Macro.t()
  defmacro group(title, opts, do_block \\ nil) do
    register_layout_path_entry(:group, nil, {:title, title}, opts, do_block)
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

    iex> AuroraUixWeb.Uix.CreateUI.LayoutConfigUI.build_default_layout_paths([], "product", %{fields: [%{field: :name}, %{field: :price}]}, :index)
    [
      %{tag: :index, state: :start, opts: [], config: {:fields, [:name, :price]}},
      %{tag: :index, state: :end}
    ]

    iex> build_default_layout_paths([], "product", %{fields: [%{field: :name}, %{field: :price}]}, :form)
    [
      %{tag: :form, state: :start, config: {:name, "product"}, opts: []},
      %{tag: :inline, state: :start, config: {:fields, [:name, :price]}, opts: []},
      %{tag: :inline, state: :end},
      %{tag: :form, state: :end}
    ]
  """
  @spec build_default_layout_paths(list, atom, map, atom) :: list
  def build_default_layout_paths(
        [],
        resource_config_name,
        %{fields: fields} = _parsed_opts,
        :index
      ) do
    columns = Enum.map(fields, & &1.field)

    [
      %{
        tag: :index,
        name: resource_config_name,
        state: :start,
        opts: [],
        config: {:fields, columns}
      },
      %{tag: :index, name: resource_config_name, state: :end}
    ]
  end

  def build_default_layout_paths([], resource_config_name, %{fields: fields} = _parsed_opts, mode)
      when mode in [:form, :show] do
    inline = Enum.map(fields, & &1.field)

    [
      %{tag: mode, name: resource_config_name, state: :start, config: [], opts: []},
      %{tag: :inline, state: :start, config: {:fields, inline}, opts: []},
      %{tag: :inline, state: :end},
      %{tag: mode, name: resource_config_name, state: :end}
    ]
  end

  def build_default_layout_paths(paths, _resource_config_name, _parsed_opts, _mode), do: paths

  ## PRIVATE

  @spec register_layout_path_entry(atom, atom, tuple | nil, keyword, any) :: Macro.t()
  defp register_layout_path_entry(tag, name, config, opts, do_block) do
    {block, opts} = Uix.extract_block_options(opts, do_block)

    registration =
      quote do
        start_attribute =
          if unquote(name),
            do: %{
              tag: unquote(tag),
              name: unquote(name),
              state: :start,
              opts: unquote(opts),
              config: unquote(config)
            },
            else: %{
              tag: unquote(tag),
              state: :start,
              opts: unquote(opts),
              config: unquote(config)
            }

        end_attribute =
          if unquote(name),
            do: %{
              tag: unquote(tag),
              name: unquote(name),
              state: :end
            },
            else: %{tag: unquote(tag), state: :end}

        Module.put_attribute(__MODULE__, :_auix_layout_paths, start_attribute)

        unquote(block)

        Module.put_attribute(__MODULE__, :_auix_layout_paths, end_attribute)
      end

    quote do
      unquote(registration)
    end
  end
end
