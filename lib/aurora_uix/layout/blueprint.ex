defmodule Aurora.Uix.Layout.Blueprint do
  @moduledoc ~S"""
  Comprehensive layout configuration system for dynamic UI generation.

  Provides DSL macros for defining declarative, nested, and flexible UI structure for
  Phoenix LiveView. Supports compile-time layout generation and field arrangement for
  index, form, and show views.

  ## Layout Hierarchy
  - Container Layouts: Index, Form, Show
  - Sub-Layouts: Inline, Stacked, Group, Sections, Section

  ## Layout Containers
  1. **Index**: Horizontal field arrangement
  2. **Form**: Editable field layout
  3. **Show**: Read-only field display

  ## Sub-Layout Types
  - `inline`: Horizontal field grouping
  - `stacked`: Vertical field arrangement
  - `group`: Visually segmented fields
  - `sections`: Tab-like field organization
  - `section`: Tab contents

  ## Layout Structures

  Each macro produces a declared layout struct (`Aurora.Uix.Layout.Declared`): `index_columns`
  an `Index`, `edit_layout` a `Form`, `show_layout` a `Show`, and the sub-layouts an `Inline`,
  `Stacked`, `Group`, `Sections` or `Section`. Each field in a list becomes a `FieldRef`.
  At compile time `Aurora.Uix.Layout.RenderTree` builds them into the render nodes
  (`Aurora.Uix.Layout.Node`) that the renderers read.

  ## Usage Examples

  ### Basic Usage
  The simplest usage creates an index layout for listing resources and a default form
  layout containing all enabled fields:

    ```elixir
    defmodule ProductViews do
      alias MyApp.Inventory
      alias MyApp.Inventory.Product

      auix_resource_metadata(:product, context: Inventory, schema: Product)

      auix_create_ui
    end
    ```

  ### Custom Layout for Index and Form
  Customize the index view to display only selected columns, and define a form layout
  with an inline group of fields:
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
  Within form and show containers, structure the UI using sub-layout commands such as
  stacked, group, and inline:

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
  Divide the form or show layout into distinct tabs using sections. 
  Each section represents a tab where only its fields are visible when selected:

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
        index_columns :product, [:reference, name: [index_renderer: &upcase_text/1]]
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
          group "Quantities", [:quantity_initial, :quantity_entries, :quantity_exits, :quantity_at_hand]
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
                group "Quantities", [:quantity_initial, :quantity_entries, :quantity_exits, :quantity_at_hand]
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

  alias Aurora.Uix.Layout.Declared
  alias Aurora.Uix.Layout.Helpers, as: LayoutHelpers

  @doc """
  Defines a form layout for resource editing.

  ## Parameters
  - `name` (atom()): Resource configuration name.
  - `opts` (keyword(), optional): Additional layout options. See below for supported options.
  - `do_block` (optional): Layout definition block.

  ## Options
  See `Aurora.Uix.Layout.Options.Form` for all supported options and behaviors.
  - `:edit_title` (binary() | (map() -> Phoenix.LiveView.Rendered.t())): The title for the edit form. Default: `"Edit {name}"`, where `{name}` is the capitalized schema name.
  - `:edit_subtitle` (binary() | (map() -> Phoenix.LiveView.Rendered.t())): The subtitle for the edit form. Default: `"Use this form to manage <strong>{title}</strong> records in your database"`, where `{title}` is the capitalized table name.
  - `:new_title` (binary() | (map() -> Phoenix.LiveView.Rendered.t())): The title for the new resource form. Default: `"New {name}"`, where `{name}` is the capitalized schema name.
  - `:new_subtitle` (binary() | (map() -> Phoenix.LiveView.Rendered.t())): The subtitle for the new resource form. Default: `"Creates a new <strong>{name}</strong> record in your database"`, where `{name}` is the capitalized schema name.
  - `:unsaved_changes_guard_disabled?` (boolean()): When `true`, closing the form modal with unsaved changes closes it without asking for confirmation. Default: `false`.
  - `:renderers` (map()): `html_type => renderer` table for the form layout. Beats
    `auix_create_ui`; a field slot beats it. With no `show_layout`, the show layout reuses it.

  ## Actions
  The following actions are available (see `Aurora.Uix.Templates.Basic.Actions.Index` for details and usage):
  - `add_row_action: {name, &fun/1}`: Adds a row action at the end.
  - `insert_row_action: {name, &fun/1}`: Inserts a row action at a specific position.
  - `replace_row_action: {name, &fun/1}`: Replaces a row action by name.
  - `remove_row_action: name`: Removes a row action by name (e.g., `:default_row_edit`).
  - `add_header_action: {name, &fun/1}`: Adds a header action at the end.
  - `insert_header_action: {name, &fun/1}`: Inserts a header action at a specific position.
  - `replace_header_action: {name, &fun/1}`: Replaces a header action by name.
  - `remove_header_action: name`: Removes a header action by name (e.g., `:default_new`).

  Association fields take the same option keys on the field itself, targeting that field's own
  action groups rather than the layout's — see `Aurora.Uix.Templates.Basic.Actions.OneToMany`,
  `Aurora.Uix.Templates.Basic.Actions.EmbedsMany` and
  `Aurora.Uix.Templates.Basic.Actions.ManyToMany` (whose `*_label_action` keys default to
  `:default_toggle_all`), plus the [Custom Actions](custom_actions.html) guide.

  ## Behavior
  - Renders an editable form layout for the resource.
  - Options allow customization of form titles, subtitles, and field arrangement.

  ## Example
  ```elixir
  edit_layout :product, edit_title: "Edit Product" do
    inline [:reference, :name, :description]
  end
  ```
  """
  @spec edit_layout(atom(), keyword(), any()) :: Macro.t()
  defmacro edit_layout(name, opts, do_block \\ nil),
    do: container_layout(:form, name, opts, do_block)

  @doc """

  Defines a read-only layout for resource display.

  ## Parameters
  - `name` (atom()): Resource configuration name.
  - `opts` (keyword(), optional): Options for customizing the show layout. See below for supported options.
  - `do_block` (optional): Layout definition block.

  ## Options
  See `Aurora.Uix.Layout.Options.Page` for all supported options and behaviors.
  - `:page_title` (binary() | (map() -> Phoenix.LiveView.Rendered.t())): The page title for the show layout. Default: `"{name}"`.
  - `:page_subtitle` (binary() | (map() -> Phoenix.LiveView.Rendered.t())): The page subtitle for the show layout. Default: `"Details"`.
  - `:renderers` (map()): `html_type => renderer` table for the show layout. Beats
    `auix_create_ui`; a field slot beats it.

  ## Actions
  The following actions are available (see `Aurora.Uix.Templates.Basic.Actions.Index` for details and usage):
  - `add_row_action: {name, &fun/1}`: Adds a row action at the end.
  - `insert_row_action: {name, &fun/1}`: Inserts a row action at a specific position.
  - `replace_row_action: {name, &fun/1}`: Replaces a row action by name.
  - `remove_row_action: name`: Removes a row action by name (e.g., `:default_row_edit`).
  - `add_header_action: {name, &fun/1}`: Adds a header action at the end.
  - `insert_header_action: {name, &fun/1}`: Inserts a header action at a specific position.
  - `replace_header_action: {name, &fun/1}`: Replaces a header action by name.
  - `remove_header_action: name`: Removes a header action by name (e.g., `:default_new`).

  ## Behavior
  - Renders fields in a disabled/read-only state.
  - All options are processed only for the `:show` tag.

  ## Examples
  ```elixir
  show_layout :product, page_title: "Product Details" do
    inline [:reference, :name, :description]
  end

  def page_title(assigns), do: ~H"Details for {@auix.name}"
  show_layout :product, page_title: &page_title/1,
                          page_subtitle: "Extra Info" do
    inline [:reference, :name, :description]
  end
  ```

  """
  @spec show_layout(atom(), keyword(), any()) :: Macro.t()
  defmacro show_layout(name, opts, do_block \\ nil),
    do: container_layout(:show, name, opts, do_block)

  @doc """
  Registers index columns and associated options for a specific resource.

  ## Parameters
  - `name` (atom): Resource configuration name.
  - `fields` (list | keyword): List of field atoms or field/option pairs to display as columns.
  - `do_block` (optional): Optional block for nested layout or further customization.


  ## Options
  - `:pagination_disabled?` (boolean()) - If true, pagination is not used for populating the index list.
  - `:sort_disabled?` (boolean() | (map() -> boolean())) - If true, the index offers no user sorting: no sortable column headers, no card-view sort control, and the `"index-sort"` event is ignored. `:order_by` still applies.
  - `:page_title` (binary() | (map() - Phoenix.LiveView.Rendered.t())): The page title for the index layout. Example: `page_title: "Products List"` or `page_title: &custom_page_title/1`.
  - `:page_subtitle` (binary() | (map() - Phoenix.LiveView.Rendered.t())): The page subtitle for the index layout. Example: `page_subtitle: "All available products"` or `page_subtitle: &custom_page_subtitle/1`.
  - `:order_by` (atom() | list() | keyword()) - Order used for displaying the index.
    Takes precedence over any order_by set in `auix_resource_metadata`.
    See `Aurora.Uix.Layout.ResourceMetadata` for details.
  - `:where` (keyword()) - Where clauses to use for filtering the items to show.
  - `:renderers` (map()) - `html_type => renderer` table for the index layout. Beats
    `auix_create_ui`; a field's `:index_renderer` beats it.
  - Field-level options can be provided as keyword lists for each field (e.g., `[name: [index_renderer: &custom_renderer/1]]`).

  ## Field-level Options
  Besides the metadata options, there are some field types that can accept specific options for changing the way they are rendered.

  - `:index_renderer` (`function/1` | `atom()`) - Renderer for this column in the index table.
    An arity-1 function receiving the field assigns (`@entity`, `@field`, `@auix`) and returning a
    `Phoenix.LiveView.Rendered.t()`, or an atom naming a predefined renderer (e.g. `:badge`; see
    `Aurora.Uix.Renderer`). Index columns do **not** fall back to `:renderer`.

  ### Fields representing **one-to-many** association.
  - `:order_by` (atom() | list() | keyword()) - `Order by` used for displaying the related items.
    Uses the same criteria as the `order_by` option described above.
  - `:where` (list()) - Allows filtering the rendered options.

  ### Fields representing **many-to-one** association related field.
  Those are the fields that referred the id that associates the many to one relation. For example: product_id.
  They are, by default, represented as a select html type.
  - `:option_label` (atom() | function()) - The label to be shown for each option. Can be:
    - atom() - Renders the field contents.
    - function/1 - Receives the entity as an argument, must return a `Phoenix.LiveView.Rendered.t()`
    - function/2 - Receives assigns and the entity as arguments, expected to return `Phoenix.LiveView.Rendered.t()`

  ## Actions
  The following actions are available (see `Aurora.Uix.Templates.Basic.Actions.Index` for details and usage):
  - `add_row_action: {name, &fun/1}`: Adds a row action at the end.
  - `insert_row_action: {name, &fun/1}`: Inserts a row action at a specific position.
  - `replace_row_action: {name, &fun/1}`: Replaces a row action by name.
  - `remove_row_action: name`: Removes a row action by name (e.g., `:default_row_edit`).
  - `add_header_action: {name, &fun/1}`: Adds a header action at the end.
  - `insert_header_action: {name, &fun/1}`: Inserts a header action at a specific position.
  - `replace_header_action: {name, &fun/1}`: Replaces a header action by name.
  - `remove_header_action: name`: Removes a header action by name (e.g., `:default_new`).

  > **Note:** Row-related actions (such as `add_row_action`, `insert_row_action`, `replace_row_action`, `remove_row_action`) will receive an `@auix.row_info` assign containing a tuple `{id, row_entity}` for the current row.

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

  # Custom per-column rendering in the index table
  index_columns :product, [:reference, name: [index_renderer: &MyApp.Views.upcase_name/1]]

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
  defmacro index_columns(name, fields, opts \\ []) do
    {_block, opts} = LayoutHelpers.extract_block_options([], opts)
    columns = LayoutHelpers.field_refs(fields, __CALLER__)

    quote do
      LayoutHelpers.declare_index(unquote(name), unquote(columns), unquote(opts))
    end
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
    children = children(block, fields, __CALLER__)

    quote do
      %Declared.Inline{children: unquote(children)}
    end
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
    children = children(block, fields, __CALLER__)

    quote do
      %Declared.Stacked{children: unquote(children)}
    end
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
    {block, fields} = LayoutHelpers.extract_block_options(opts, do_block)
    children = children(block, fields, __CALLER__)

    quote do
      %Declared.Group{title: unquote(title), children: unquote(children)}
    end
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
    {block, _opts} = LayoutHelpers.extract_block_options(opts, do_block)
    children = children(block, [], __CALLER__)

    quote do
      %Declared.Sections{children: unquote(children)}
    end
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
    {list_opts, do_block} = trailing_options(opts, do_block)
    {block, fields_and_opts} = LayoutHelpers.extract_block_options(list_opts, do_block)
    {fields, section_opts} = LayoutHelpers.split_sub_layout_opts(fields_and_opts, [:default])
    children = children(block, fields, __CALLER__)

    quote do
      %Declared.Section{
        label: unquote(label),
        default?: unquote(Keyword.get(section_opts, :default, false)),
        children: unquote(children)
      }
    end
  end

  ## PRIVATE

  @spec container_layout(:form | :show, atom(), keyword(), Macro.t()) :: Macro.t()
  defp container_layout(layout_type, name, opts, do_block) do
    {block, opts} = LayoutHelpers.extract_block_options(opts, do_block)

    quote do
      LayoutHelpers.declare_container(
        unquote(layout_type),
        unquote(name),
        unquote(LayoutHelpers.prepare_block(block)),
        unquote(opts)
      )
    end
  end

  # `section "Label", [:field], default: true` passes its options where the block would go.
  @spec trailing_options(list(), term()) :: {list(), term()}
  defp trailing_options(opts, [{key, _value} | _rest] = trailing) when key != :do,
    do: {opts ++ trailing, nil}

  defp trailing_options(opts, do_block), do: {opts, do_block}

  # The block's sub-layouts first, then the listed fields.
  @spec children(Macro.t(), list(), Macro.Env.t()) :: Macro.t()
  defp children(block, fields, env) do
    quote do
      unquote(LayoutHelpers.prepare_block(block)) ++
        unquote(LayoutHelpers.field_refs(fields, env))
    end
  end
end
