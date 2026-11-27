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
- `:destructive?` — `true` for an action that destroys data. Index cards list destructive row actions last in their ⋮ menu, in the danger color (default `false`; `true` for `:default_row_delete`)

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
│  │  [toggle_filters]  [sort]  [clear]  [submit]  [new] │  │
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
│  ┌─ :index_footer_actions ─────────────────────────────┐  │
│  │  [← prev]  [1] [2] [3]  [next →]   (pagination)     │  │
│  └─────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────┘
```

> The slot labels above (`:index_header_actions`, etc.) are internal names used in socket assigns. Use the operation key prefixes in the table below as your `index_columns` options.
> `:index_selected_all_actions` is the header of the selection checkbox column.
> `:index_filters_actions` shows only while the filters are open: in the last filter cell of the
> table, and in a card of its own in the card view.

| Operation Key Prefix | Available Operations | Defaults You Can Target |
|---|---|---|
| `*_header_action` | add, insert, replace, remove | `:default_toggle_filters`, `:default_sort`, `:default_clear`, `:default_submit`, `:default_new` |
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

### One-to-Many Layout Actions

```
┌──────────────────────────────────────────────────────────┐
│  ┌─ :one_to_many_header_actions ──────────────────────┐  │
│  │  [new]                                             │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  ┌──────────────────────┬─────────────────────────────┐  │
│  │  field  field        │ :one_to_many_row_actions    │  │
│  │  ...                 │ [show]  [edit]  [delete]    │  │
│  └──────────────────────┴─────────────────────────────┘  │
│                                                          │
│  ┌─ :one_to_many_footer_actions ──────────────────────┐  │
│  │  (empty by default)                                │  │
│  └────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘
```

| Operation Key Prefix | Available Operations | Defaults You Can Target |
|---|---|---|
| `*_header_action` | add, insert, replace, remove | `:default_new` |
| `*_row_action` | add, insert, replace, remove | `:default_row_show`, `:default_row_edit`, `:default_row_delete` |
| `*_footer_action` | add, insert, replace, remove | *(none by default)* |

New, edit and delete render in the form only, and New only once the parent record is saved; show
renders in both the form and the show view. In a form or show view embedded as a
[reusable component](../core/components.md) these default actions render nothing.

### Embeds-Many Layout Actions

```
┌──────────────────────────────────────────────────────────┐
│  ┌─ :embeds_many_header_actions ──────────────────────┐  │
│  │  [add new entry]                                   │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│   entry fields                                           │
│  ┌─ :embeds_many_existing_actions ────────────────────┐  │
│  │  [remove entry]              (once per entry)      │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  ┌─ :embeds_many_footer_actions ──────────────────────┐  │
│  │  [add new entry]             (when entries exist)  │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  New entry dialog                                        │
│  ┌─ :embeds_many_new_entry_actions ───────────────────┐  │
│  │  [add]                                             │  │
│  └────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘
```

| Operation Key Prefix | Available Operations | Defaults You Can Target |
|---|---|---|
| `*_header_action` | add, insert, replace, remove | `:default_header_enable_add_entry` |
| `*_existing_action` | add, insert, replace, remove | `:default_remove_entry` |
| `*_new_entry_action` | add, insert, replace, remove | `:default_add_entry` |
| `*_footer_action` | add, insert, replace, remove | `:default_footer_enable_add_entry` |

The default embeds-many actions render in the form only. There is no row operation for embeds-many
fields.

### Many-to-Many Layout Actions

A many-to-many field renders as a list of checkboxes over the candidate records. It has three
action strips: one right of the label, one at the top right, and one below the list.

```
┌──────────────────────────────────────────────────────────┐
│  ┌─ :many_to_many_label_actions ─┐                       │
│  │  Label  [-]                   │  ┌─ :..._header_actions ┐
│  └───────────────────────────────┘  │  (empty by default) │
│                                     └─────────────────────┘
│  ┌────────────────────────────────────────────────────┐  │
│  │  [x] Record A                                      │  │
│  │  [ ] Record B                                      │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  ┌─ :many_to_many_footer_actions ─────────────────────┐  │
│  │  (empty by default)                                │  │
│  └────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘
```

**many_to_many layout options:**

| Operation Key Prefix | Available Operations | Defaults You Can Target |
|---|---|---|
| `*_label_action` | add, insert, replace, remove | `:default_toggle_all` |
| `*_header_action` | add, insert, replace, remove | *(none by default)* |
| `*_footer_action` | add, insert, replace, remove | *(none by default)* |

`:default_toggle_all` (in `Aurora.Uix.Templates.Basic.Actions.ManyToMany`) is a tri-state checkbox:
checked when every candidate is a member, unchecked when none is, and a dash when only some are.
Clicking a checked toggle clears the membership; clicking it in either other state selects
everything. It rides the parent form's change event, so the new membership lands in the form params
and survives the next validation.

### Multi-Select Layout Actions

A multi-value select — an array attribute whose values are constrained to a fixed set, such as an
`{:array, Ecto.Enum}` field or an Ash array attribute with an `items: [one_of: …]` constraint —
renders as the same checkbox list, over its declared options rather than over related records. It
has the same three action strips.

```
┌──────────────────────────────────────────────────────────┐
│  ┌─ :multi_select_label_actions ─┐                       │
│  │  Label  [-]                   │  ┌─ :..._header_actions ┐
│  └───────────────────────────────┘  │  (empty by default) │
│                                     └─────────────────────┘
│  ┌────────────────────────────────────────────────────┐  │
│  │  [x] Fragile                                       │  │
│  │  [ ] Perishable                                    │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  ┌─ :multi_select_footer_actions ─────────────────────┐  │
│  │  (empty by default)                                │  │
│  └────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘
```

**multi_select layout options:**

| Operation Key Prefix | Available Operations | Defaults You Can Target |
|---|---|---|
| `*_label_action` | add, insert, replace, remove | `:default_toggle_all` |
| `*_header_action` | add, insert, replace, remove | *(none by default)* |
| `*_footer_action` | add, insert, replace, remove | *(none by default)* |

`:default_toggle_all` here lives in `Aurora.Uix.Templates.Basic.Actions.MultiSelect` and behaves
exactly as the many-to-many one, over the option list instead of the candidate records.

## Action Operations

Aurora UIX provides four operations to customize actions in layout options. The operation key you write combines the operation (`add_`, `insert_`, `replace_`, `remove_`) with the slot suffix (`_header_action`, `_row_action`, etc.) — for example `add_header_action`, `replace_row_action`. Because the same suffix maps to different internal groups per layout type, `add_header_action` inside `index_columns` targets the index header, while the same key inside `edit_layout` targets the form header.

**Add Action** — Appends an action to the end of the group:
```elixir
index_columns :product, [:name],
  # Append a custom archive button after the default row actions
  add_row_action: {:archive, &MyViews.archive_action/1},
  # Append an Export CSV button after the default header actions (toggle_filters, sort, clear, submit, new)
  add_header_action: {:export, &MyViews.export_action/1}

edit_layout :product,
  # Append a "Save and Continue" button after the default Save button in a form
  add_footer_action: {:save_continue, &MyViews.save_and_continue_action/1} do
  stacked [:name]
end
```

**Insert Action** — Prepends an action to the beginning of the group:
```elixir
index_columns :product, [:name],
  # Prepend an Approve button before the default row actions (show, edit, delete)
  insert_row_action: {:approve, &MyViews.approve_action/1},
  # Prepend a Help link before the default header actions
  insert_header_action: {:help, &MyViews.help_action/1}

edit_layout :product,
  # Prepend a Cancel button before the default Save button in a form
  insert_footer_action: {:cancel, &MyViews.cancel_action/1} do
  stacked [:name]
end
```

**Replace Action** — Replaces an existing action by name:
```elixir
index_columns :product, [:name],
  # Swap the default edit icon for a custom styled one in row actions
  replace_row_action: {:default_row_edit, &MyViews.custom_edit_action/1},
  # Swap the default New button for one that opens a slide-over instead of navigating
  replace_header_action: {:default_new, &MyViews.slide_over_new_action/1}

edit_layout :product,
  # Swap the default Save button for one with a loading spinner
  replace_footer_action: {:default_save, &MyViews.spinner_save_action/1} do
  stacked [:name]
end
```

**Remove Action** — Removes an action by name:
```elixir
index_columns :product, [:name],
  # Remove the Show icon from row actions (edit and delete remain)
  remove_row_action: :default_row_show,
  # Remove the New button from the header (useful for read-only index views)
  remove_header_action: :default_new,
  # Remove the card view's sort control (the column headers still sort)
  remove_header_action: :default_sort,
  # Remove the bulk delete button shown when rows are selected
  remove_selected_action: :default_selected_delete_all

# Remove the Back link from a show page footer
show_layout :product, remove_footer_action: :default_back do
  stacked [:name]
end
```

All operations accept `{action_name, &function/1}` pairs (except remove, which only needs the name). A row action also takes options as a third element: `{action_name, &function/1, destructive?: true}`.

## Configuring Actions via Layout DSL

Actions are configured in your UI layout definition using the `auix_create_ui` DSL. The configuration pattern is declarative and happens at compile time:

```elixir
auix_create_ui do
  index_columns(:product, [:id, :name, :list_price],
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

## Action Icons

Every default action that renders a button or a link has an icon. Below the `sm` breakpoint
(640px wide) a default action button shows only its icon; its label stays on the button as
`title` and `aria-label`. From 641px up nothing changes: a text button shows its label, and an
icon action, such as a row action, shows its icon.

`action_icons:` changes the icon of a default action. The action keeps its function component,
its events and its label. The keys are the default action names of the layout:

```elixir
index_columns :product, [:name],
  action_icons: [default_new: :"hero-sparkles", default_selected_delete_all: "hero-archive-box-x-mark"]

edit_layout :product, action_icons: [default_save: "hero-check"] do
  stacked [:reference, :name]
end

show_layout :product, action_icons: [default_back: "←"] do
  stacked [:reference, :name]
end
```

An icon is told apart by its value:

| Value | Renders |
|---|---|
| an atom such as `:"hero-sparkles"`, a string starting with `hero-` | the Heroicon of that name |
| a string starting with `/` or `http` | an image with that URL |
| any other string, such as `"←"` | the text itself |
| a named function of arity 1, such as `&MyAppWeb.Icons.new_icon/1` | the icon it returns for the action's assigns |

The keys and their default icons:

| Layout | Key | Default icon |
|---|---|---|
| `index_columns` | `:default_row_show` | `hero-eye` |
| `index_columns` | `:default_row_edit` | `hero-pencil` |
| `index_columns` | `:default_row_delete` | `hero-trash` |
| `index_columns` | `:default_selected_uncheck_all` | `hero-x-circle` |
| `index_columns` | `:default_selected_delete_all` | `hero-trash` |
| `index_columns` | `:default_selected_check_all` | `hero-check-circle` |
| `index_columns` | `:default_toggle_filters` | `hero-funnel` |
| `index_columns` | `:default_clear` | `hero-x-mark` |
| `index_columns` | `:default_submit` | `hero-magnifying-glass` |
| `index_columns` | `:default_new` | `hero-plus` |
| `edit_layout` | `:default_save` | `hero-check` |
| `show_layout` | `:default_edit` | `hero-pencil` |
| `show_layout` | `:default_back` | `hero-arrow-left` |
| one-to-many field | `:default_new` | `hero-plus` |
| one-to-many field | `:default_row_show` | `hero-eye` |
| one-to-many field | `:default_row_edit` | `hero-pencil` |
| one-to-many field | `:default_row_delete` | `hero-trash` |
| embeds-many field | `:default_header_enable_add_entry` | `hero-plus` |
| embeds-many field | `:default_footer_enable_add_entry` | `hero-plus` |
| embeds-many field | `:default_add_entry` | `hero-plus` |
| embeds-many field | `:default_remove_entry` | `hero-trash` |

`:default_toggle_all_selected`, `:default_sort` and `:default_pagination` are not keys: they
render a checkbox, a sort control with fixed icons and a pager. Many-to-many and multi-select fields have no keys: their
only default action is the `:default_toggle_all` checkbox. An unknown key fails compilation, and
the error lists the valid keys of the layout. **Delete selected** keeps its count badge when only
its icon shows.

One-to-many and embeds-many fields take `action_icons:` in their field options, next to the
action operations of [Association Actions](#association-actions):

```elixir
edit_layout :product do
  stacked([
    :name,
    product_transactions: [action_icons: [default_new: "hero-sparkles"]]
  ])
end
```

### Custom actions on mobile

Aurora UIX cannot know the names of your custom actions, so it resolves no icon for them and
their markup stays the same at every width. To make a custom button follow the breakpoint, render
its content with `<.action_content>` from the core components, and put its label on the button as
`title` and `aria-label`:

```elixir
defmodule MyAppWeb.ProductActions do
  use Aurora.Uix.CoreComponentsImporter

  def archive_action(assigns) do
    ~H"""
    <.button type="button" phx-click="archive" title="Archive" aria-label="Archive">
      <.action_content icon="hero-archive-box" label="Archive" />
    </.button>
    """
  end
end
```

`<.action_content>` shows its `label` from 641px up and its `icon` below. With
`icon_always?={true}` it shows the icon at every width and hides only the label below the
breakpoint. `<.action_icon icon={...} />` renders an icon value alone, as the table above reads it.

### Row actions in cards

In the card view the show action is the card itself: tapping the card opens the record's show
view, and the selection checkbox and the ⋮ menu keep their own taps. An action that replaces
`:default_row_show` becomes the card's tap target; with `remove_row_action: :default_row_show`
tapping the card opens nothing.

Every row action, show included, sits in a ⋮ menu at the end of the card header, in the order
they are declared. Destructive actions go last, below a divider, in the danger color.

`:default_row_delete` is destructive. Mark your own action with `destructive?: true`:

```elixir
index_columns :product, [:reference, :name],
  add_row_action: {:archive, &MyAppWeb.ProductActions.archive_action/1, destructive?: true}
```

An action that replaces `:default_row_delete` stays destructive unless it says
`destructive?: false`. Each menu item gets a 44px touch target. The default row actions carry
their label as `title` and `aria-label`; give your own action both, as
[Custom actions on mobile](#custom-actions-on-mobile) shows.

The default row actions carry the `auix-index-row-action` class, which the card menu and the
card's tap target style. Give your own action the class to style it the same way. Without it,
the menu styles the action's top `a` and `button` elements, and the tap target its top element.

## Action Handlers

Action handlers are simple function components that receive an `assigns` map. Every action gets
`:auix`, the context of the view; association actions get a few keys more:

| Action group | Assigns |
|---|---|
| index, form and show | `auix` |
| one-to-many row | `auix`, with `auix.row_info` |
| one-to-many header and footer, many-to-many, multi-select | `auix`, `field` |
| embeds-many header and footer | `auix`, `field`, `target` |
| embeds-many existing entry | `auix`, `field`, `target`, `entry_index` |
| embeds-many new entry | `auix`, `field`, `target`, `form_id` |

`target` is the embeds-many component, for `phx-target`.

Example handler:

```elixir
defmodule MyApp.CustomActions do
  use Aurora.Uix.CoreComponentsImporter

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
    <.auix_link patch={"#{@auix[:index_new_link]}"} name={"auix-new-#{@auix.module}"}>
      <.button>New Item</.button>
    </.auix_link>
    """
  end
end
```

`use Aurora.Uix.CoreComponentsImporter` brings in `Phoenix.Component` and the core components, such
as `<.button>`.

### Important Implementation Notes

**Action Function Signature:**
- Actions must be functions with arity 1 that accept assigns
- Must return rendered output (use `~H"""..."""` sigil)
- Must be named functions (not anonymous functions)

**Available Assigns in Actions:**
- `@auix` — Contains all Aurora UIX context
  - `.row_info` — Tuple of `{id, entity}` for row actions (see Row Info Structure below)
  - `.entity` — Current entity for form/show actions
  - `.module` — Resource module name, as used in element names
  - `.name` — Resource display name
  - `.primary_key` — Primary key field(s)
  - `.uri_path` — Current URI path for navigation
  - `.selection` — Selection state (index layouts only)
  - `.pagination` — Pagination state (index layouts only)
  - `.filters_enabled?` — Whether filters panel is open
  - `._myself` — The component's `@myself` in form and show actions; target it with `phx-target` to send an event to the
    form or show handler (see [Targeting the Component](../core/liveview.md#targeting-the-component))

**Row Info Structure:**

The `@auix.row_info` in row actions is a 2-tuple containing:
1. **ID** (first element) — In the index, the DOM id of the stream item; in a one-to-many list,
   the primary key value
2. **Entity** (second element) — In the index, the record as a plain map with its fields; in a
   one-to-many list, the record struct

```elixir
# In the index
{dom_id, entity} = assigns.auix.row_info
# dom_id = "products-123"
# entity = %{id: 123, name: "Widget", ...}

# Pattern match in the function head
def process_action(%{auix: %{row_info: {_id, entity}}} = assigns) do
  assigns = Map.put(assigns, :entity, entity)

  ~H"""
  <button type="button" phx-click="process" phx-value-id={@entity.id}>
    Process {@entity.name}
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

## Bulk Actions on Selected Rows

A bulk action runs over the rows the user ticked in the index. It takes three pieces: a control
in the selected-actions strip, a layout option that places it there, and a handler clause that
does the work. The built-in controls are `:default_selected_uncheck_all`, `:default_selected_delete_all` and
`:default_selected_check_all`; `remove_selected_action` removes any of them. This recipe adds a **Deactivate selected** button that sets `inactive` on every
selected product.

**1. The control.** The selected-actions strip calls each action with `%{auix: auix}`.
`auix.selection` is an `Aurora.Uix.Selection` struct:

| Field | Content |
|---|---|
| `selected` | a `MapSet` of the selected rows' ids, across every page |
| `selected_count` | the number of selected rows |
| `toggle_all_mode` | `:none`, or `:check` / `:uncheck` while **Check all** / **Uncheck all** is still collecting ids — `selected` is incomplete until it returns to `:none` |

Render the control only when rows are selected and no toggle-all is running, as the built-in
**Delete selected** does:

```elixir
defmodule MyAppWeb.ProductActions do
  use Aurora.Uix.CoreComponentsImporter

  def deactivate_selected(
        %{auix: %{selection: %{selected_count: count, toggle_all_mode: :none}}} = assigns
      )
      when count > 0 do
    ~H"""
    <.button
      type="button"
      class="auix-index-all-action-button"
      phx-click="deactivate_selected"
      name={"auix-selected-deactivate-#{@auix.module}"}
    >
      Deactivate selected
    </.button>
    """
  end

  def deactivate_selected(assigns), do: ~H""
end
```

**2. The layout option.** `add_selected_action` appends the control after the built-in ones;
`handler_module` names the module that receives its event:

```elixir
auix_create_ui do
  index_columns(:product, [:reference, :name, :inactive],
    handler_module: MyAppWeb.ProductIndexHandler,
    add_selected_action: {:deactivate_selected, &MyAppWeb.ProductActions.deactivate_selected/1}
  )
end
```

**3. The handler.** The control's `phx-click` reaches the index LiveView, which passes it to
`auix_handle_event/3`. The event carries no ids; read them from
`socket.assigns.auix.selection.selected`:

```elixir
defmodule MyAppWeb.ProductIndexHandler do
  use Aurora.Uix.Templates.Basic.Handlers.IndexImpl

  alias Aurora.Uix.Events
  alias MyApp.Inventory
  alias MyApp.Inventory.Product

  @impl IndexImpl
  def auix_handle_event("deactivate_selected", _params, socket) do
    Enum.each(socket.assigns.auix.selection.selected, fn id ->
      id |> Inventory.get_product!() |> Inventory.update_product(%{inactive: true})
    end)

    Events.changed(Product)
    Events.reset_selection()

    {:noreply, put_flash(socket, :info, "Products deactivated")}
  end

  def auix_handle_event(event, params, socket), do: super(event, params, socket)
end
```

- Keep the last clause. Overriding `auix_handle_event/3` replaces the default, and every
  built-in index event — selection, filters, sorting, pagination, **Delete selected** — arrives
  through it.
- Aurora UIX never writes the records. The handler calls the host's own context function or Ash
  action; validation and its errors are the host's. This sketch ignores an
  `{:error, changeset}` result; report it in a real application.
- `Events.changed(Product)` re-reads the page so the new values show, and
  `Events.reset_selection()` clears the selection, which hides the control again. See
  [Refreshing the Index from a Custom Action](#refreshing-the-index-from-a-custom-action).

## Refreshing the Index from a Custom Action

A custom action that changes data tells the index through `Aurora.Uix.Events`. Handle the
action's event in an index handler module (see
[LiveView Integration › Index Handler Hook](../core/liveview.md#index-handler-hook-liveview)):

```elixir
defmodule MyApp.ProductIndexHandler do
  use Aurora.Uix.Templates.Basic.Handlers.IndexImpl

  alias Aurora.Uix.Events
  alias MyApp.Inventory.Product

  @impl IndexImpl
  def auix_handle_event("archive_selected", _params, socket) do
    Enum.each(socket.assigns.auix.selection.selected, &MyApp.Inventory.archive_product/1)

    Events.changed(Product)
    Events.reset_selection()

    {:noreply, put_flash(socket, :info, "Products archived")}
  end

  def auix_handle_event(event, params, socket), do: super(event, params, socket)
end
```

- `Events.changed(Product)` makes every open index over `Product` re-read its current page,
  this one included. Publish `Events.created/1`, `Events.updated/1` or `Events.deleted/2`
  instead when the action knows which records it wrote.
- `Events.reset_selection()` clears this view's selection only; other users keep theirs.
- With `pubsub_server` unset, publishing does nothing. Call `Events.refresh()` to re-read this
  view's page.
- `refresh/1` and `reset_selection/1` take the index LiveView's pid. A handler running inside
  the view calls them with no argument; a task or job that holds the pid passes it.

See [LiveView Integration › Reacting to Data Changes](../core/liveview.md#reacting-to-data-changes)
for the event shape and how an open index reacts.

## Association Actions

For one-to-many, embeds-many and many-to-many associations, actions are configured similarly within the field configuration:

```elixir
auix_create_ui do
  edit_layout :product do
    stacked([
      :name,
      :list_price,
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

The same keys target the many-to-many checkbox list — and, unchanged, a multi-value select's. Because
the key names are resolved against the field they are declared on, `add_header_action` here means the
checkbox group's header — not the enclosing `edit_layout`'s:

```elixir
auix_create_ui do
  edit_layout :product do
    stacked([
      :name,
      suppliers: [
        # Swap the built-in tri-state toggle for your own control beside the label
        replace_label_action: {:default_toggle_all, &__MODULE__.my_toggle/1},
        # The header and footer groups ship empty and exist for exactly this
        add_header_action: {:invert, &__MODULE__.invert_selection/1},
        add_footer_action: {:manage, &__MODULE__.manage_suppliers_link/1}
      ]
    ])
  end
end
```

## How Actions Are Processed

Each time a view builds its actions:

1. The groups are emptied and the template adds its default actions: show, edit and delete rows,
   filters, selection, New and pagination in the index; Save in the form; Edit and Back in the show
   view; the actions of the [association fields](#action-groups-by-layout-type). The form has no
   default Cancel action.
2. The action options of the layout, or of the field, are applied one by one **in the order you
   write them**.

So `add_*_action` appends to what is there at that point, `insert_*_action` prepends (the last
insert ends up first), and `replace_*_action` and `remove_*_action` do nothing when no action of
that name exists yet.

## Action Modification Under the Hood

Actions are stored in the socket's `assigns.auix` map under their respective action group keys. The modification functions (`add_auix_action`, `insert_auix_action`, `replace_auix_action`, `remove_auix_action`) from `Aurora.Uix.Templates.Basic.Helpers` manipulate these lists during layout setup.

For a complete list of available action groups, call `Aurora.Uix.Action.action_groups()`.

See `Aurora.Uix.Action` module for the complete mapping of action names to their groups and helper functions.

## Related guides

- [Customizing & Extending Aurora UIX](customization.md) — the central customization hub
- [Layout System](../core/layouts.md) — the layout macros that take these options
- [LiveView Integration](../core/liveview.md) — handling the events your custom actions fire
- [Ash Integration](../core/ash_integration.md#custom-actions) — Ash *resource* actions (a different concept)
