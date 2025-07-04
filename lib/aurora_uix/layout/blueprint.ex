defmodule Aurora.Uix.Layout.Blueprint do
  @moduledoc ~S"""
  Comprehensive layout configuration system for dynamic UI generation.

  ## Key Features
  - Enables declarative, nested, and flexible UI structure definition for Phoenix LiveView.
  - Supports compile-time layout generation and field arrangement for index, form, and show views.

  ## Layout Hierarchy
  - Container Layouts: Index, Form, Show
  - Sub-Layouts: Inline, Stacked, Group, Sections

  ## Layout Containers
  1. **Index**: Horizontal field arrangement
  2. **Form**: Editable field layout
  3. **Show**: Read-only field display

  ## Sub-Layout Types
  - `inline`: Horizontal field grouping
  - `stacked`: Vertical field arrangement
  - `group`: Visually segmented fields
  - `sections`: Tab-like field organization

  ## Layout Tree Element Structure

  Internally, each layout is represented by a list of maps (called "paths"), where each entry contains the following keys:

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

      auix_resource_metadata(:product, context: Inventory, schema: Product)

      auix_create_ui
    end
    ```

  ### Custom Layout for Index and Form
  Customize the index view to display only selected columns, and define a form layout with an inline group of fields:
    ```elixir
    defmodule ProductViews do
      alias MyApp.Inventory
      alias MyApp.Inventory.Product

      auix_resource_metadata(:product, context: Inventory, schema: Product)

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

      auix_resource_metadata(:product, context: Inventory, schema: Product)

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

      auix_resource_metadata(:product, context: Inventory, schema: Product)

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

      auix_resource_metadata(:product, context: Inventory, schema: Product)

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

      auix_resource_metadata(:product, context: Inventory, schema: Product)

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

      auix_resource_metadata(:product, context: Inventory, schema: Product)

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

  alias Aurora.Uix.CounterAgent
  alias Aurora.Uix.Layout.Helpers, as: LayoutHelpers

  @doc false
  defmacro __using__(_opts) do
    quote do
      import Aurora.Uix.Layout.Blueprint
    end
  end

  @doc """
  Defines a layout for resource editing.

  ## Parameters
  - `name` (atom()): Resource configuration name
  - `opts` (keyword(), optional): Additional layout options. See below for supported options.
  - `do_block` (optional): Layout definition block

  ## Options
  The following options are supported for form layouts (see `Aurora.Uix.Layout.Options.Form` for details):

    * `:edit_title` - The title for the edit form. Accepts a `binary()` (static title) or a function of arity 1 that receives assigns and
        returns a Phoenix.LiveView.Rendered. Default: `"Edit {name}"`, where {name} is the capitalized schema name.
    * `:edit_subtitle` - The subtitle for the edit form. Accepts a `binary()` or a function of arity 1.
        Default: `"Use this form to manage <strong>{title}</strong> records in your database"`, where {title} is the capitalized table name.
    * `:new_title` - The title for the new resource form (when in `:index` context). Accepts a `binary()` or a function of arity 1.
        Default: `"New {name}"`, where {name} is the capitalized schema name.
    * `:new_subtitle` - The subtitle for the new resource form (when in `:index` context). Accepts a `binary()` or a function of arity 1.
        Default: `"Creates a new <strong>{name}</strong> record in your database"`, where {name} is the capitalized schema name.

  For additional option behaviors and rendering details, see `Aurora.Uix.Layout.Options.Form`.

  ## Example
  ```elixir
    edit_layout :product, edit_title: "Edit Product" do
      inline [:reference, :name, :description]
    end
  ```
  """
  @spec edit_layout(atom(), keyword(), any()) :: Macro.t()
  defmacro edit_layout(name, opts, do_block \\ nil) do
    LayoutHelpers.register_dsl_entry(:form, name, nil, opts, do_block)
  end

  @doc """
  Defines a read-only layout for resource display.

  ## Parameters
  - `name` (atom()) - Resource configuration name.
  - `opts` (keyword(), optional) - Options for customizing the show layout. See below for supported options.
  - `do_block` (optional) - Layout definition block.

  ## Options
  The following options are supported for show layouts (see `Aurora.Uix.Layout.Options.Page` for details):

    * `:page_title` - The page title for the show layout.
        Accepts a `binary()` (static title) or a function of arity 1 that receives assigns and
        returns a Phoenix.LiveView.Rendered. Default: `"{name}"`, where {name} is the capitalized schema name.
    * `:page_subtitle` - The page subtitle for the show layout. Accepts a `binary()` or a function of arity 1.
        Default: `"Details"`.

  For additional option behaviors and rendering details, see `Aurora.Uix.Layout.Options.Page`.

  ## Behavior
  - Renders fields in a disabled/read-only state.
  - All options are processed only for the `:show` tag.

  ## Examples

      show_layout :product, page_title: "Product Details" do
        inline [:reference, :name, :description]
      end

      def page_title(assigns), do: ~H"Details for {@auix.name}"
      show_layout :product, page_title: &page_title/1,
                              page_subtitle: "Extra Info" do
        inline [:reference, :name, :description]
      end

  """
  @spec show_layout(atom(), keyword(), any()) :: Macro.t()
  defmacro show_layout(name, opts, do_block \\ nil) do
    LayoutHelpers.register_dsl_entry(:show, name, nil, opts, do_block)
  end

  @doc """
  Registers index columns and associated options for a specific resource.

  Supports both field selection and index-level options, including those described in
  `Aurora.Uix.Layout.Options.Page` (such as `:page_title` and `:page_subtitle`), as well as default and custom row/header actions.

  ## Parameters
  - `name` (atom()): Resource configuration name.
  - `fields` (list() | keyword()): List of field atoms or field/option pairs to display as columns.
  - `do_block` (optional): Optional block for nested layout or further customization.

  ## Options
  The following options are supported for index layouts (see `Aurora.Uix.Layout.Options.Page`):

  - `:page_title` (binary() | (assigns -> Rendered.t())): The page title for the index layout.
    - Example: `page_title: "Products List"`
    - Example: `page_title: &custom_page_title/1` where `def custom_page_title(assigns), do: ~H"<span>Custom Title</span>"`
    - Default: `"Listing {title}"` (where `{title}` is the resource title)

  - `:page_subtitle` (binary() | (assigns -> Rendered.t())): The page subtitle for the index layout.
    - Example: `page_subtitle: "All available products"`
    - Example: `page_subtitle: &custom_page_subtitle/1` where `def custom_page_subtitle(assigns), do: ~H"<span>Subtitle</span>"`
    - Default: `"Details"`

  - Field-level options can be provided as keyword lists for each field (e.g., `[name: [renderer: &custom_renderer/1]]`).

  ## Actions
  The following actions are supported for index layouts (see `Aurora.Uix.Web.Templates.Basic.Actions.Index`):

  > **Note:** Row-related actions (such as `add_row_action`, `insert_row_action`, `remove_row_action`)
    will receive an `@auix.row_info` assign containing a tuple `{id, row_entity}` for the current row.

  - `add_row_action: {name, &fun/1}`: Adds a row action at the end.
  - `insert_row_action: {name, &fun/1}`: Inserts a row action at a specific position (see `Aurora.Uix.Web.Templates.Basic.Actions.Index` for details).
  - `remove_row_action: name`: Removes a row action by name (e.g., `:default_row_edit`).

  - `add_header_action: {name, &fun/1}`: Adds a header action at the end.
  - `insert_header_action: {name, &fun/1}`: Inserts a header action at a specific position (see `Aurora.Uix.Web.Templates.Basic.Actions.Index` for details).
  - `remove_header_action: name`: Removes a header action by name (e.g., `:default_new`).

  - Example: `add_row_action: {:custom_action, &custom_action/1}` where `def custom_action(assigns), do: ~H"<span>Custom</span>"`
  - Example: `insert_row_action: {:special, &special_action/1}`
  - Example: `remove_row_action: :default_row_edit`

  ## Behavior
  - Fields listed in `fields` will be rendered as columns in the index table.
  - Options and actions allow customization of the index page title, subtitle, and available actions.

  ## Examples
  ```elixir
  # Basic usage with default actions and titles
  index_columns :product, [:name, :price]

  # Custom page title and subtitle
  index_columns :product, [:name, :price],
    page_title: "Products List",
    page_subtitle: "All available products"

  # Add a custom row action and remove the default delete action
  defmodule MyApp.Actions do
    def custom_action(assigns) do
      ~H"<.link navigate={~p\"/edit_page\"}"
    end
  end
  index_columns :product, [:name, :price],
    add_row_action: {:custom, &MyApp.Actions.custom_action/1},
    remove_row_action: :default_row_delete
  ```
  """
  @spec index_columns(atom(), keyword() | list(), any()) :: Macro.t()
  defmacro index_columns(name, fields, do_block \\ nil) do
    LayoutHelpers.register_dsl_entry(:index, name, {:fields, fields}, [], do_block)
  end

  @doc """
  Defines an inline sub-layout that groups fields horizontally within a form or show container.

  This macro accepts a list of fields (or UI override options) and an optional `do` block for defining nested layouts.
  It is used to arrange fields side-by-side, either as a standalone block or as part of a larger layout.

  ## Parameters
  - `fields` (list()): A list of field identifiers or keyword options for field-specific UI customizations.
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
  @spec inline(keyword(), any()) :: Macro.t()
  defmacro inline(fields, do_block \\ nil) do
    {block, fields} = LayoutHelpers.extract_block_options(fields, do_block)
    LayoutHelpers.register_dsl_entry(:inline, nil, {:fields, fields}, [], block)
  end

  @doc """
  Defines a stacked sub-layout that groups fields vertically within a form or show container.

  This macro accepts a list of fields (or UI override options) and an optional `do` block for further nesting.
  It is typically used to arrange fields one below the other, creating a vertical grouping that aids in visual organization.

  ## Parameters
  - `fields` (list()): A list of field identifiers or keyword options for UI customizations.
  - `block`: An optional `do` block containing nested layout definitions.

  ## Example
  ```elixir
    stacked [:quantity_initial, :quantity_entries, :quantity_exits, :quantity_at_hand]
  ```
  """
  @spec stacked(keyword(), any()) :: Macro.t()
  defmacro stacked(fields, do_block \\ nil) do
    {block, fields} = LayoutHelpers.extract_block_options(fields, do_block)
    LayoutHelpers.register_dsl_entry(:stacked, nil, {:fields, fields}, [], block)
  end

  @doc """
  Defines a group sub-layout to visually segment related fields under a common title.

  ## Parameters
  - `title` (string()): The title of the group.
  - `opts` (keyword()): Additional options for the group layout.
  - `block`: An optional `do` block containing nested layout definitions.

  ## Example
  ```elixir
    group "Identification", [:reference, :name, :description]
  ```
  """
  @spec group(atom(), keyword(), any()) :: Macro.t()
  defmacro group(title, opts, do_block \\ nil) do
    LayoutHelpers.register_dsl_entry(
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
  - `opts` (keyword()): Additional options for configuring the sections container.
  - `block`: A `do` block containing one or more `section` definitions.

  ## Example
  ```elixir
    sections do
      section "Details", [:reference, :name]
      section "Prices", [:msrp, :rrp]
    end
  ```
  """
  @spec sections(keyword(), any()) :: Macro.t()
  defmacro sections(opts, do_block \\ nil) do
    LayoutHelpers.register_dsl_entry(
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
  - `label` (string()): The label for the section.
  - `opts` (keyword()): Additional options for the section layout.
  - `block`: An optional `do` block for nested layout definitions.

  ## Example
  ```elixir
    section "Details", [:reference, :name, :description]
  ```
  """
  @spec section(binary(), keyword(), any()) :: Macro.t()
  defmacro section(label, opts, do_block \\ nil) do
    LayoutHelpers.register_dsl_entry(
      :section,
      nil,
      [label: label, tab_id: "auix-section-#{unique_titled_id(label)}"],
      opts,
      do_block
    )
  end

  @doc """
  Generates a default layout_tree structure for rendering UI components based on the given layout type.

  ## Parameters
  - `paths` (list()): An existing list of paths. If empty, default paths are generated.
  - `resource_config` (atom()): The associated resource configuration.
  - `layout_type` (atom()): The rendering layout type (`:index`, `:form`, or `:show`).

  ## Returns
  - map(): A map representing the UI structure.

  ## Modes and Behaviour

  - **`:index` layout types**: Generates an `:index` structure using all available fields as columns.
  - **`:form` and `:show` layout types**: Generates a `:layout` structure containing an `:inline` group with all fields.
  - If paths are already provided, they are returned unchanged.

  ## Example

    iex> Aurora.Uix.Layout.Blueprint.build_default_layout_paths([], "product", %{fields: [%{field: :name}, %{field: :price}]}, [], :index)
    [
      %{tag: :index, state: :start, opts: [], config: {:fields, [:name, :price]}},
      %{tag: :index, state: :end}
    ]

    iex> build_default_layout_paths([], "product", %{fields: [%{field: :name}, %{field: :price}]}, [], :form)
    [
      %{tag: :form, state: :start, config: {:name, "product"}, opts: []},
      %{tag: :inline, state: :start, config: {:fields, [:name, :price]}, opts: []},
      %{tag: :inline, state: :end},
      %{tag: :form, state: :end}
    ]
  """
  @spec build_default_layout_paths(list(), map(), keyword(), atom()) :: map()
  def build_default_layout_paths(
        [],
        resource_config,
        _opts,
        :index
      ) do
    columns =
      resource_config
      |> Map.get(:fields_order, [])
      |> Enum.reject(
        &(get_in(resource_config, [
            Access.key!(:fields),
            Access.key!(&1),
            Access.key!(:type)
          ]) in [:many_to_one_association, :one_to_many_association])
      )
      |> Enum.map(&%{tag: :field, name: &1, inner_elements: [], opts: []})

    %{
      tag: :index,
      name: resource_config.name,
      config: [],
      opts: [],
      inner_elements: columns
    }
  end

  def build_default_layout_paths([], resource_config, opts, layout_type)
      when layout_type in [:form, :show] do
    columns =
      resource_config
      |> Map.get(:fields_order, [])
      |> Enum.reject(
        &(get_in(resource_config, [
            Access.key!(:fields),
            Access.key!(&1),
            Access.key!(:type)
          ]) in [:many_to_one_association, :one_to_many_association])
      )
      |> Enum.map(&%{tag: :field, name: &1, inner_elements: [], opts: []})

    fields_layout_mode = Keyword.get(opts, :default_fields_layout, :stacked)

    fields_layout = %{tag: fields_layout_mode, config: [], opts: [], inner_elements: columns}

    %{
      tag: layout_type,
      name: resource_config.name,
      config: [],
      opts: [],
      inner_elements: [fields_layout]
    }
  end

  def build_default_layout_paths([], resource_config, _opts, layout_type),
    do: %{name: resource_config.name, tag: layout_type, config: [], opts: [], inner_elements: []}

  def build_default_layout_paths([paths], _resource_config, _opts, _layout_type), do: paths

  @doc """
  Parses a list of paths to handle sections based on the given layout type.

  ## Parameters
  - `paths` (list()): A list of layout_tree maps representing the layout structure.
  - `layout_type` (atom()): The layout type of parsing, such as `:index` or other modes.

  ## Returns
  - `list()`: A list of parsed paths with sections processed according to the layout type.

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
  @spec parse_sections(map(), atom()) :: map()
  def parse_sections(layout_tree, layout_type) when layout_type in [:form, :show] do
    pid = CounterAgent.start_counter()

    layout_tree
    |> Map.get(:inner_elements, [])
    |> normalize_sections_and_tabs(pid)
    |> then(&Map.put(layout_tree, :inner_elements, &1))
  end

  def parse_sections(layout_tree, _layout_type), do: layout_tree

  ## PRIVATE

  @spec unique_titled_id(binary() | nil) :: binary()
  defp unique_titled_id(nil), do: unique_titled_id("untitled")
  defp unique_titled_id(""), do: unique_titled_id("untitled")

  defp unique_titled_id(title) do
    slug = normalize_title(title)

    unique_suffix =
      :md5
      |> :crypto.hash(title <> to_string(:os.system_time(:millisecond)))
      |> Base.encode16(case: :lower)
      |> String.slice(0, 8)

    unique_int = :erlang.unique_integer([:positive])

    "#{slug}-#{unique_suffix}#{unique_int}"
  end

  @spec normalize_title(binary()) :: binary()
  defp normalize_title(title) do
    title
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/, "")
    |> String.replace(~r/\s+/, "_")
    |> String.trim("_")
  end

  ## -------------------
  ## Sections parsing
  ## -------------------

  # Recursively processes a list of layout elements to establish the hierarchy and relationships
  # between sections and tabs. It maintains indices for sections and tabs while traversing the
  # elements tree, ensuring proper nesting and parent-child relationships.
  #
  # Parameters:
  # - elements: List of layout elements to process
  # - sections_id: ID of the current sections container (nil for root level)
  # - sections_index: Counter for section numbering (starts at 0 and never resets)
  # - tab_parent_id: ID of the parent tab if any (nil for root level)
  # - tab_index: Counter for tab numbering within a section (starts at 0 and resets when a sections container starts)
  # - tab_active?: Indicates if a tab is already active within the sections.
  # - result: Accumulator for processed elements
  #
  # Returns a tuple containing:
  # - List of processed elements with updated configuration
  # - Final section index
  @spec normalize_sections_and_tabs(
          list(),
          pid(),
          binary() | nil,
          integer(),
          binary() | nil,
          integer(),
          boolean(),
          list()
        ) :: list()
  defp normalize_sections_and_tabs(
         elements,
         counter_pid,
         sections_id \\ nil,
         sections_index \\ 0,
         tab_parent_id \\ nil,
         tab_index \\ 0,
         tab_active? \\ false,
         result \\ []
       )

  defp normalize_sections_and_tabs(
         [],
         _counter_pid,
         _sections_id,
         _section_index,
         _tab_parent_id,
         _tab_index,
         tab_active?,
         result
       ) do
    result
    |> Enum.reverse()
    |> maybe_mark_first_tab(tab_active?)
  end

  defp normalize_sections_and_tabs(
         [%{tag: :sections, config: config, inner_elements: inner_elements} = element | elements],
         counter_pid,
         _sections_id,
         _sections_index,
         tab_parent_id,
         _tab_index,
         _tab_active?,
         result
       ) do
    next_sections_index = CounterAgent.next_count(counter_pid)

    new_inner_elements =
      normalize_sections_and_tabs(
        inner_elements,
        counter_pid,
        config[:sections_id],
        next_sections_index,
        tab_parent_id
      )

    tabs_info =
      new_inner_elements
      |> Enum.filter(&(&1.tag == :section))
      |> Enum.map(&Map.new(&1.config))

    new_config =
      config
      |> Keyword.put(:sections_index, next_sections_index)
      |> Keyword.put(:tabs, tabs_info)

    new_element = Map.merge(element, %{config: new_config, inner_elements: new_inner_elements})

    normalize_sections_and_tabs(
      elements,
      counter_pid,
      config[:sections_id],
      next_sections_index,
      tab_parent_id,
      0,
      false,
      [new_element | result]
    )
  end

  defp normalize_sections_and_tabs(
         [
           %{tag: :section, opts: opts, config: config, inner_elements: inner_elements} = element
           | elements
         ],
         counter_pid,
         sections_id,
         sections_index,
         tab_parent_id,
         tab_index,
         tab_active?,
         result
       ) do
    next_tab_index = tab_index + 1
    next_tab_active? = !tab_active? and opts[:default] == true

    new_inner_elements =
      normalize_sections_and_tabs(
        inner_elements,
        counter_pid,
        sections_id,
        sections_index,
        config[:tab_id],
        next_tab_index
      )

    new_config =
      Keyword.merge(config,
        active: opts[:default] == true,
        sections_id: sections_id,
        sections_index: sections_index,
        tab_parent_id: tab_parent_id,
        tab_index: next_tab_index
      )

    new_element = Map.merge(element, %{config: new_config, inner_elements: new_inner_elements})

    normalize_sections_and_tabs(
      elements,
      counter_pid,
      sections_id,
      sections_index,
      tab_parent_id,
      next_tab_index,
      next_tab_active?,
      [new_element | result]
    )
  end

  defp normalize_sections_and_tabs(
         [%{inner_elements: inner_elements} = element | elements],
         counter_pid,
         sections_id,
         sections_index,
         tab_parent_id,
         tab_index,
         tab_active?,
         result
       ) do
    new_inner_elements =
      normalize_sections_and_tabs(
        inner_elements,
        counter_pid,
        sections_id,
        sections_index,
        tab_parent_id,
        tab_index,
        tab_active?
      )

    new_element = Map.put(element, :inner_elements, new_inner_elements)

    normalize_sections_and_tabs(
      elements,
      counter_pid,
      sections_id,
      sections_index,
      tab_parent_id,
      tab_index,
      tab_active?,
      [new_element | result]
    )
  end

  @spec maybe_mark_first_tab(list(), boolean()) :: list()
  defp maybe_mark_first_tab(elements, true), do: elements

  defp maybe_mark_first_tab(elements, _) do
    elements
    |> Enum.reduce(
      {[], false},
      fn
        element, {acc, true} ->
          {[element | acc], true}

        %{tag: :section, config: config} = element, {acc, false} ->
          config
          |> Keyword.update(:active, true, fn _ -> true end)
          |> then(&Map.put(element, :config, &1))
          |> then(&{[&1 | acc], true})

        element, {acc, tab_active?} ->
          {[element | acc], tab_active?}
      end
    )
    |> elem(0)
    |> Enum.reverse()
  end
end
