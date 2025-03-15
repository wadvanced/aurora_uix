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
      - Sub-layout commands: `:stacked`, `:group`, `:inline`, and `:sections`

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
          sections do
            section "Details", [:reference, :name, :description]
            section "Prices", [:msrp, :rrp, :list_price]
            section "Images", [:image, :thumbnail]
          end
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
          sections do
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
  Defines a layout for an edit form.

  This macro is used within `auix_create_ui` to structure the UI layout for editing a resource.

  ## Parameters
  - `name` (atom): The name of the UI configuration to which the layout applies.
  - `opts` (keyword): Additional options for configuring the layout.
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
  Defines a layout for a show view.

  This macro is used within `auix_create_ui` to structure the UI layout for displaying a resource.
  A show layout overrides the default form layout by rendering all fields in a disabled or read-only state.

  ## Parameters
  - `name` (atom): The name of the UI configuration to which the layout applies.
  - `opts` (keyword): Additional options for configuring the layout.
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

  @doc """
  Defines an inline sub-layout that groups fields horizontally within a form or show container.

  This macro accepts a list of fields (or UI override options) and an optional `do` block for defining nested layouts.
  It is used to arrange fields side-by-side, either as a standalone block or as part of a larger layout.

  ## Parameters
  - `fields` (list): A list of field identifiers or keyword options for field-specific UI customizations.
  - `block`: An optional `do` block containing nested layout definitions.

  ## Examples
  Inline without a nested block:
  ```elixir
    inline [:reference, :name, :description]
  ```
  Inline with nested sub-layouts:
  ```elixir
    inline do
      group "Basic Info" do
        inline [:reference, :name]
        stacked [:description, :notes]
      end
    end
  ```
  """
  @spec inline(Keyword.t(), any) :: Macro.t()
  defmacro inline(fields, do_block \\ nil) do
    {block, fields} = Uix.extract_block_options(fields, do_block)
    register_layout_path_entry(:inline, nil, {:fields, fields}, [], block)
  end

  @doc """
  Defines a stacked sub-layout that groups fields vertically within a form or show container.

  This macro accepts a list of fields (or UI override options) and an optional `do` block for further nesting.
  It is typically used to arrange fields one below the other, creating a vertical grouping that aids in visual organization.

  ## Parameters
  - `fields` (list): A list of field identifiers or keyword options for UI customizations.
  - `block`: An optional `do` block containing nested layout definitions.

  ## Example
  ```elixir
    stacked [:quantity_initial, :quantity_entries, :quantity_exits, :quantity_at_hand]
  ```
  """
  @spec stacked(Keyword.t(), any) :: Macro.t()
  defmacro stacked(fields, do_block \\ nil) do
    {block, fields} = Uix.extract_block_options(fields, do_block)
    register_layout_path_entry(:stacked, nil, {:fields, fields}, [], block)
  end

  @doc """
  Defines a group sub-layout to visually segment related fields under a common title.

  ## Parameters
  - `title` (string): The title of the group.
  - `opts` (keyword): Additional options for the group layout.
  - `block`: An optional `do` block containing nested layout definitions.

  ## Example
  ```elixir
    group "Identification", [:reference, :name, :description]
  ```
  """
  @spec group(atom, Keyword.t(), any) :: Macro.t()
  defmacro group(title, opts, do_block \\ nil) do
    register_layout_path_entry(
      :group,
      nil,
      [title: title, group_id: "auix-group-#{unique_titled_id(title)}"],
      opts,
      do_block
    )
  end

  @doc """
  Defines a sections container that groups multiple section entries into tab-like structures.

  ## Parameters
  - `opts` (keyword): Additional options for configuring the sections container.
  - `block`: A `do` block containing one or more `section` definitions.

  ## Example
  ```elixir
    sections do
      section "Details", [:reference, :name]
      section "Prices", [:msrp, :rrp]
    end
  ```
  """
  @spec sections(keyword, any) :: Macro.t()
  defmacro sections(opts, do_block \\ nil) do
    register_layout_path_entry(
      :sections,
      nil,
      [sections_id: "auix-#{unique_titled_id("sections")}"],
      opts,
      do_block
    )
  end

  @doc """
  Defines a section within a sections container, representing a tab that contains a specific set of fields.

  ## Parameters
  - `label` (string): The label for the section.
  - `opts` (keyword): Additional options for the section layout.
  - `block`: An optional `do` block for nested layout definitions.

  ## Example
  ```elixir
    section "Details", [:reference, :name, :description]
  ```
  """
  @spec section(binary, keyword, any) :: Macro.t()
  defmacro section(label, opts, do_block \\ nil) do
    register_layout_path_entry(
      :section,
      nil,
      [label: label, tab_id: "auix-section-#{unique_titled_id(label)}"],
      opts,
      do_block
    )
  end

  @doc """
  Generates a default path structure for rendering UI components based on the given mode.

  ## Parameters
  - `paths` (list): An existing list of paths. If empty, default paths are generated.
  - `resource_config_name` (atom): The resource configuration name.
  - `parsed_opts` (map): A map containing parsed options, including:
  - `:fields` (list): A list of field structures.
  - `mode` (atom): The rendering mode (`:index`, `:form`, or `:show`).

  ## Returns
  - `list`: A list of tagged maps representing the UI structure.

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
    stacked = Enum.map(fields, & &1.field)

    [
      %{tag: mode, name: resource_config_name, state: :start, config: [], opts: []},
      %{tag: :stacked, state: :start, config: {:fields, stacked}, opts: []},
      %{tag: :stacked, state: :end},
      %{tag: mode, name: resource_config_name, state: :end}
    ]
  end

  def build_default_layout_paths(paths, _resource_config_name, _parsed_opts, _mode), do: paths

  @doc """
  Parses a list of paths to handle sections based on the given mode.

  ## Parameters
  - `paths` (list): A list of path maps representing the layout structure.
  - `mode` (atom): The mode of parsing, such as `:index` or other modes.

  ## Returns
  - `list`: A list of parsed paths with sections processed according to the mode.

  ## Examples
    iex> paths = [
      %{tag: :sections, state: :start},
      %{tag: :section, state: :start, config: [tab_id: "tab1", label: "Tab 1"], opts: []},
      %{tag: :section, state: :end},
      %{tag: :sections, state: :end}
      ]
    iex> parse_sections(paths, :form)
    [
      %{
        tag: :sections,
        state: :start,
        config: [%{active: true, label: "Tab 1", tab_id: "tab1"}]
      },
      %{
        tag: :section,
        state: :start,
        config: [active: true, tab_id: "tab1", label: "Tab 1"],
        opts: []
      },
      %{tag: :section, state: :end},
      %{tag: :sections, state: :end}
    ]

  """
  @spec parse_sections(list, atom) :: list
  def parse_sections(paths, mode) when mode in [:form, :show] do
    parse_path(paths, [])
  end

  def parse_sections(paths, _mode), do: paths

  ## PRIVATE

  @spec register_layout_path_entry(atom, atom, keyword | tuple | nil, keyword, any) :: Macro.t()
  defp register_layout_path_entry(tag, name, config, opts, do_block) do
    {block, opts} = Uix.extract_block_options(opts, do_block)

    registration =
      quote do
        start_attribute =
          %{
            tag: unquote(tag),
            name: unquote(name),
            state: :start,
            opts: unquote(opts),
            config: unquote(config)
          }

        end_attribute =
          %{
            tag: unquote(tag),
            name: unquote(name),
            state: :end
          }

        Module.put_attribute(__MODULE__, :_auix_layout_paths, start_attribute)

        unquote(block)

        Module.put_attribute(__MODULE__, :_auix_layout_paths, end_attribute)
      end

    quote do
      unquote(registration)
    end
  end

  defp unique_titled_id(nil), do: unique_titled_id("untitled")
  defp unique_titled_id(""), do: unique_titled_id("untitled")

  defp unique_titled_id(title) do
    slug = normalize_title(title)

    unique_suffix =
      :md5
      |> :crypto.hash(title <> to_string(:os.system_time(:millisecond)))
      |> Base.encode16(case: :lower)
      |> String.slice(0, 8)

    monotonic = :erlang.unique_integer([:monotonic, :positive])

    "#{slug}-#{unique_suffix}#{monotonic}"
  end

  defp normalize_title(title) do
    title
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/, "")
    |> String.replace(~r/\s+/, "_")
    |> String.trim("_")
  end

  ## Sections parsing
  @spec parse_path(list, list) :: list
  defp parse_path(
         [%{tag: :sections, state: :start, config: config} = sections_path | rest],
         result
       ) do
    collected =
      rest
      |> parse_path([])
      |> Enum.map(&associate_tabs(&1, config[:sections_id]))
      |> ensure_single_active_tab(config[:sections_id])

    new_sections_path =
      collected
      |> extract_tabs(config[:sections_id])
      |> then(&Map.put(sections_path, :config, &1))

    result
    |> add_to_paths(collected)
    |> add_to_paths(new_sections_path)
  end

  defp parse_path([path | rest], result) do
    collected = parse_path(rest, [])

    result
    |> add_to_paths(collected)
    |> add_to_paths(path)
  end

  defp parse_path([], result), do: result

  @spec add_to_paths(list, list | map) :: list
  defp add_to_paths(result, [path | rest]), do: add_to_paths([path | result], rest)
  defp add_to_paths(result, []), do: Enum.reverse(result)
  defp add_to_paths(result, single_path), do: [single_path | result]

  @spec associate_tabs(map, binary) :: map
  defp associate_tabs(
         %{tag: :section, state: :start, config: config, opts: opts} = section_path,
         sections_id
       ) do
    if Keyword.has_key?(config, :sections_id),
      do: section_path,
      else:
        config
        |> Keyword.put(:sections_id, sections_id)
        |> Keyword.put(:active, Keyword.get(opts, :default, false))
        |> then(&Map.put(section_path, :config, &1))
  end

  defp associate_tabs(path, _sections_id), do: path

  @spec ensure_single_active_tab(list, binary) :: list
  defp ensure_single_active_tab(paths, sections_id) do
    active_count = Enum.count(paths, &accept_tab?(&1, sections_id))
    ensure_single_active_tab(paths, sections_id, active_count)
  end

  @spec ensure_single_active_tab(list, binary, integer) :: list
  defp ensure_single_active_tab(paths, sections_id, 0) do
    paths
    |> Enum.reduce({[], true}, &mark_active_tab(&1, &2, sections_id))
    |> elem(0)
    |> Enum.reverse()
  end

  defp ensure_single_active_tab(paths, _sections_id, 1), do: paths

  defp ensure_single_active_tab(paths, sections_id, _count),
    do: ensure_single_active_tab(paths, sections_id, 0)

  defp mark_active_tab(
         %{tag: :section, state: :start, config: config} = tab_path,
         {acc, active},
         sections_id
       ) do
    if config[:sections_id] == sections_id do
      config
      |> Keyword.update!(:active, fn _ -> active end)
      |> then(&Map.put(tab_path, :config, &1))
      |> then(&{[&1 | acc], false})
    else
      {[tab_path | acc], active}
    end
  end

  defp mark_active_tab(path, {acc, active}, _sections_id), do: {[path | acc], active}

  @spec accept_tab?(map, binary) :: boolean
  defp accept_tab?(%{tag: :section, state: :start, config: config}, sections_id),
    do: config[:sections_id] == sections_id and config[:active]

  defp accept_tab?(_tab, _sections_id), do: false

  @spec extract_tabs(list, binary) :: list
  defp extract_tabs(paths, sections_id) do
    paths
    |> Enum.filter(fn
      %{tag: :section, state: :start, config: config} -> config[:sections_id] == sections_id
      _ -> false
    end)
    |> Enum.map(&Map.new(&1.config))
  end
end
