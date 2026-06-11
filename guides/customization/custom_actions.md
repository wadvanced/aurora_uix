# Custom Actions

Actions are function components representing user interactions (buttons, links, etc.) attached to different parts of your views. Aurora UIX provides a comprehensive action system with support for adding, replacing, inserting, and removing actions via layout configuration.

> #### Not Ash actions {: .info}
> "Actions" in this guide are **UI action buttons and links** rendered by Aurora UIX layouts.
> They are unrelated to Ash resource actions (`:read`, `:create`, `:update`, `:destroy`) — for
> those, see [Ash Integration → Custom Actions](../core/ash_integration.md#custom-actions).

## Understanding the Action System

Actions are defined as `Aurora.Uix.Action` structs with:

- `:name` — unique identifier for the action (atom or binary)
- `:function_component` — a function (arity 1) that receives assigns and returns rendered output

Actions are organized into **action groups** specific to each layout type. Each group represents a location where actions are rendered (headers, footers, rows, etc.). To customize a group you write an **operation key** as a layout option — the key tells Aurora UIX both which group to target and what to do (add, insert, replace, or remove). The same key name (e.g. `add_header_action`) targets a different internal group depending on which layout macro you are inside.

The action system works by:

1. **Setting defaults** - Template-specific modules add default actions (edit, delete, new, etc.)
2. **Removing defaults** - Via `remove_*_action` configuration
3. **Adding actions** - Via `add_*_action` configuration
4. **Inserting actions** - Via `insert_*_action` (prepends to list)
5. **Replacing actions** - Via `replace_*_action` (overrides existing by name)

## Action Groups by Layout Type

### Index Layout Actions

```
┌───────────────────────────────────────────────────────────┐
│  PAGE HEADER                                              │
│  ┌─ :index_header_actions ─────────────────────────────┐  │
│  │  [toggle_filters]  [clear]  [submit]  [new]         │  │
│  └─────────────────────────────────────────────────────┘  │
│                                                           │
│  ┌─ :index_selected_all_actions ───────────────────────┐  │
│  │  [toggle_all_selected checkbox]                     │  │
│  ├─ :index_selected_actions ───────────────────────────┤  │
│  │  [uncheck_all]  [delete_all]  [check_all]           │  │
│  └─────────────────────────────────────────────────────┘  │
│                                                           │
│  ┌──────┬────────────────┬─────────────────────────────┐  │
│  │  □   │  Col A  Col B  │  :index_row_actions         │  │
│  │  □   │  ...           │  [show]  [edit]  [delete]   │  │
│  │  □   │  ...           │  [show]  [edit]  [delete]   │  │
│  └──────┴────────────────┴─────────────────────────────┘  │
│                                                           │
│  ┌─ :index_filters_actions ────────────────────────────┐  │
│  │  (filters panel, shown when toggle_filters active)  │  │
│  └─────────────────────────────────────────────────────┘  │
│                                                           │
│  ┌─ :index_footer_actions ─────────────────────────────┐  │
│  │  [← prev]  [1] [2] [3]  [next →]   (pagination)     │  │
│  └─────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────┘
```

> The slot labels above (`:index_header_actions`, etc.) are internal names used in socket assigns. Use the operation key prefixes in the table below as your `index_columns` options.

| Operation Key Prefix | Available Operations | Defaults You Can Target |
|---|---|---|
| `*_header_action` | add, insert, replace, remove | `:default_toggle_filters`, `:default_clear`, `:default_submit`, `:default_new` |
| `*_selected_all_action` | replace, remove *(no add / insert)* | `:default_toggle_all_selected` |
| `*_selected_action` | add, insert, replace, remove | `:default_selected_uncheck_all`, `:default_selected_delete_all`, `:default_selected_check_all` |
| `*_filters_action` | add, insert, replace, remove | *(none by default)* |
| `*_row_action` | add, insert, replace, remove | `:default_row_show`, `:default_row_edit`, `:default_row_delete` |
| `*_footer_action` | add, insert, replace, remove | `:default_pagination` |

### Form Layout Actions

```
┌──────────────────────────────────────────┐
│  ┌─ :form_header_actions ─────────────┐  │
│  │  (empty by default)                │  │
│  └────────────────────────────────────┘  │
│                                          │
│   field: value                           │
│   field: value                           │
│                                          │
│  ┌─ :form_footer_actions ─────────────┐  │
│  │  [Save]                            │  │
│  └────────────────────────────────────┘  │
└──────────────────────────────────────────┘
```

> Use the operation key prefixes below as your `edit_layout` options.

| Operation Key Prefix | Available Operations | Defaults You Can Target |
|---|---|---|
| `*_header_action` | add, insert, replace, remove | *(none by default)* |
| `*_footer_action` | add, insert, replace, remove | `:default_save` |

### Show Layout Actions

```
┌──────────────────────────────────────────┐
│  ┌─ :show_header_actions ─────────────┐  │
│  │  [Edit]                            │  │
│  └────────────────────────────────────┘  │
│                                          │
│   field: value                           │
│   field: value                           │
│                                          │
│  ┌─ :show_footer_actions ─────────────┐  │
│  │  [← Back]                          │  │
│  └────────────────────────────────────┘  │
└──────────────────────────────────────────┘
```

> Use the operation key prefixes below as your `show_layout` options.

| Operation Key Prefix | Available Operations | Defaults You Can Target |
|---|---|---|
| `*_header_action` | add, insert, replace, remove | `:default_edit` |
| `*_footer_action` | add, insert, replace, remove | `:default_back` |

### One-to-Many & Embeds-Many Layout Actions

```
┌──────────────────────────────────────────────────────────┐
│  ┌─ :one_to_many_header_actions ──────────────────────┐  │
│  │  (embeds_many: new entry button)                   │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  ┌──────────────────────┬─────────────────────────────┐  │
│  │  field  field        │ :one_to_many_row_actions    │  │
│  │  ...                 │ :embeds_many_row_actions    │  │
│  └──────────────────────┴─────────────────────────────┘  │
│                                                          │
│  ┌─ :embeds_many_new_entry_actions ───────────────────┐  │
│  │  (inline new-entry form controls)                  │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  ┌─ :embeds_many_existing_actions ────────────────────┐  │
│  │  (per-row existing entry controls)                 │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  ┌─ :one_to_many_footer_actions ──────────────────────┐  │
│  │  (empty by default)                                │  │
│  └────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘
```

> `one_to_many` and `embeds_many` share similar slot positions but differ in available operation keys — see both tables below.

**one_to_many layout options:**

| Operation Key Prefix | Available Operations | Defaults You Can Target |
|---|---|---|
| `*_header_action` | add, insert, replace, remove | *(none by default)* |
| `*_row_action` | add, insert, replace, remove | *(none by default)* |
| `*_footer_action` | add, insert, replace, remove | *(none by default)* |

**embeds_many layout options:**

| Operation Key Prefix | Available Operations | Defaults You Can Target |
|---|---|---|
| `*_header_action` | add, insert, replace, remove | *(none by default)* |
| `*_new_entry_action` | add, insert, replace, remove | *(none by default)* |
| `*_existing_action` | add, insert, replace, remove | *(none by default)* |
| `*_footer_action` | add, insert, replace, remove | *(none by default)* |

## Action Operations

Aurora UIX provides four operations to customize actions in layout options. The operation key you write combines the operation (`add_`, `insert_`, `replace_`, `remove_`) with the slot suffix (`_header_action`, `_row_action`, etc.) — for example `add_header_action`, `replace_row_action`. Because the same suffix maps to different internal groups per layout type, `add_header_action` inside `index_columns` targets the index header, while the same key inside `edit_layout` targets the form header.

**Add Action** — Appends an action to the end of the group:
```elixir
# Append a custom archive button after the default row actions
add_row_action: {:archive, &MyViews.archive_action/1}

# Append an Export CSV button after the default header actions (toggle_filters, clear, submit, new)
add_header_action: {:export, &MyViews.export_action/1}

# Append a "Save and Continue" button after the default Save button in a form
add_footer_action: {:save_continue, &MyViews.save_and_continue_action/1}
```

**Insert Action** — Prepends an action to the beginning of the group:
```elixir
# Prepend an Approve button before the default row actions (show, edit, delete)
insert_row_action: {:approve, &MyViews.approve_action/1}

# Prepend a Help link before the default header actions
insert_header_action: {:help, &MyViews.help_action/1}

# Prepend a Cancel button before the default Save button in a form
insert_footer_action: {:cancel, &MyViews.cancel_action/1}
```

**Replace Action** — Replaces an existing action by name:
```elixir
# Swap the default edit icon for a custom styled one in row actions
replace_row_action: {:default_row_edit, &MyViews.custom_edit_action/1}

# Swap the default New button for one that opens a slide-over instead of navigating
replace_header_action: {:default_new, &MyViews.slide_over_new_action/1}

# Swap the default Save button for one with a loading spinner
replace_footer_action: {:default_save, &MyViews.spinner_save_action/1}
```

**Remove Action** — Removes an action by name:
```elixir
# Remove the Show icon from row actions (edit and delete remain)
remove_row_action: :default_row_show

# Remove the New button from the header (useful for read-only index views)
remove_header_action: :default_new

# Remove the Back link from a show page footer
remove_footer_action: :default_back
```

All operations accept `{action_name, &function/1}` pairs (except remove, which only needs the name).

## Configuring Actions via Layout DSL

Actions are configured in your UI layout definition using the `auix_create_ui` DSL. The configuration pattern is declarative and happens at compile time:

```elixir
auix_create_ui do
  index_columns(:product, [:id, :name, :price],
    # Remove a default action
    remove_row_action: :default_row_edit,

    # Add a custom action (appended to list)
    add_row_action: {:custom_action, &__MODULE__.custom_handler/1},

    # Insert a custom action (prepended to list)
    insert_row_action: {:first_action, &__MODULE__.first_handler/1},

    # Replace an existing action by name
    replace_header_action: {:default_new, &__MODULE__.custom_new_handler/1},

    # Add header and footer actions
    add_header_action: {:export, &__MODULE__.export_handler/1},
    add_footer_action: {:bulk_action, &__MODULE__.bulk_handler/1}
  )
end
```

For complete worked examples of customizing index, form, and show actions inside layouts,
see [Layout System → Actions: Customizing Buttons & Links](../core/layouts.md#actions-customizing-buttons--links).

## Action Handlers

Action handlers are simple function components that receive an `assigns` map containing:

- `:auix` - Context information including:
  - `:row_info` - For row actions: tuple of {id, entity_map}
  - `:module` - Module/resource name
  - `:uri_path` - Base path for routing
  - `:index_new_link` - Link for creating new records
  - And other layout context...
- `:field` - Field information (for association actions)
- `:target` - LiveComponent target for event handling

Example handler:

```elixir
defmodule MyApp.CustomActions do
  use Phoenix.Component
  import Aurora.Uix.Templates.Basic.RoutingComponents

  def custom_edit_handler(assigns) do
    ~H"""
      <.auix_link 
        patch={"/#{@auix.uri_path}/#{elem(@auix.row_info, 1).id}/edit"} 
        name={"auix-edit-#{@auix.module}"}
      >
        Custom Edit
      </.auix_link>
    """
  end

  def custom_new_handler(assigns) do
    ~H"""
      <.auix_link 
        patch={"#{@auix[:index_new_link]}"} 
        name={"auix-new-#{@auix.module}"}
      >
        <.button>New Item</.button>
      </.auix_link>
    """
  end
end
```

### Important Implementation Notes

**Action Function Signature:**
- Actions must be functions with arity 1 that accept assigns
- Must return rendered output (use `~H"""..."""` sigil)
- Must be named functions (not anonymous functions)

**Available Assigns in Actions:**
- `@auix` — Contains all Aurora UIX context
  - `.row_info` — Tuple of `{index, entity}` for row actions (see Row Info Structure below)
  - `.entity` — Current entity for form/show actions
  - `.module` — Resource module name
  - `.name` — Resource display name
  - `.primary_key` — Primary key field(s)
  - `.uri_path` — Current URI path for navigation
  - `.selection` — Selection state (index layouts only)
  - `.pagination` — Pagination state (index layouts only)
  - `.filters_enabled?` — Whether filters panel is open

**Row Info Structure:**

The `@auix.row_info` in row actions is a 2-tuple containing:
1. **Index/ID** (first element) — The stream identifier or row ID from Phoenix LiveView streams
2. **Entity** (second element) — The actual entity struct/map for the row

```elixir
# Example row_info tuple structure
row_info = {"products-123", %Product{id: 123, name: "Widget", price: 29.99}}

# Extracting components
{stream_id, entity} = assigns.auix.row_info
# stream_id = "products-123"
# entity = %Product{id: 123, name: "Widget", price: 29.99}

# Common patterns for accessing data:
# 1. Get the primary key value
id = row_info_id(assigns.auix)  # Using helper function

# 2. Access entity fields directly
{_id, product} = assigns.auix.row_info
price = product.price

# 3. Pattern match in function head
def custom_action(%{auix: %{row_info: {_index, entity}}} = assigns) do
  ~H"""
  <button phx-click="process" phx-value-id={entity.id}>
    Process {entity.name}
  </button>
  """
end
```

**Helper for Extracting Primary Keys:**

Aurora UIX provides a helper to safely extract primary key values from row_info:

```elixir
defp row_info_id(%{row_info: {_index, row_entity}, primary_key: primary_key}) do
  Aurora.Uix.Templates.Basic.Helpers.primary_key_value(row_entity, primary_key)
end
```

This helper handles both single and composite primary keys:
- Single key: Returns the value directly (e.g., `123`)
- Composite keys: Returns a list of values (e.g., `[123, 456]`)

**Helper Functions:**
- Use `Aurora.Uix.Templates.Basic.Helpers.primary_key_value/2` to extract entity IDs
- Use `<.auix_link>` component for navigation with routing stack preservation
- Use `<.auix_back>` component for back navigation
- Use `Phoenix.LiveView.JS` for client-side interactions

**Action Styling:**
- Use `auix-*` CSS classes for consistent styling
- Row action icons: `auix-icon-size-5` with context classes (`auix-icon-info`, `auix-icon-safe`, `auix-icon-danger`)
- Buttons: `auix-button` (primary, default), `auix-button--alt` (secondary), `auix-index-all-action-button` (index-bar select-all). Pick exactly one — `<.button>` already supplies the structural base.

## Association Actions

For one-to-many and embeds-many associations, actions are configured similarly within the field configuration:

```elixir
auix_create_ui do
  edit_layout :product do
    stacked([
      :name,
      :price,
      product_transactions: [
        # Configure actions for the nested table
        add_header_action: {:custom_new, &__MODULE__.custom_new_transaction/1},
        replace_row_action: {:default_row_edit, &__MODULE__.custom_edit_transaction/1},
        add_footer_action: {:import, &__MODULE__.import_handler/1}
      ]
    ])
  end
end
```

## How Actions Are Processed

The action system processes configuration in this order:

1. **Initialize** - Default actions are added by the template (index adds show/edit/delete, form adds save/cancel, etc.)
2. **Remove** - Specified actions are removed from their groups
3. **Add** - New actions are appended
4. **Insert** - Actions are prepended
5. **Replace** - Actions matching the name are replaced
6. **Finalize** - Layout options are applied via `Aurora.Uix.Templates.Basic.Actions.modify_actions/2`

## Action Modification Under the Hood

Actions are stored in the socket's `assigns.auix` map under their respective action group keys. The modification functions (`add_auix_action`, `insert_auix_action`, `replace_auix_action`, `remove_auix_action`) from `Aurora.Uix.Templates.Basic.Helpers` manipulate these lists during layout setup.

For a complete list of available action groups, call `Aurora.Uix.Action.action_groups()`.

See `Aurora.Uix.Action` module for the complete mapping of action names to their groups and helper functions.

## Related guides

- [Customizing & Extending Aurora UIX](customization.md) — the central customization hub
- [Layout System](../core/layouts.md) — worked examples of action customization inside layouts
- [LiveView Integration](../core/liveview.md) — handling the events your custom actions fire
- [Ash Integration](../core/ash_integration.md#custom-actions) — Ash *resource* actions (a different concept)
