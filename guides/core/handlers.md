# Handlers and Events

The generated LiveView and components delegate their behavior to handler modules. Write your own
to change how a view loads, saves or answers an event, and leave the rest to the defaults.

## Handler Hooks

A handler module `use`s the default implementation of one view and overrides the `auix_*` callbacks
it needs, calling `super` for the default behavior.

### Attaching a Handler

A handler is named in the layout that renders the view:

| Layout option | On | Handler of |
|---|---|---|
| `handler_module` | `index_columns` | the Index LiveView |
| `component_handler_module` | `index_columns` | the `IndexComponent` |
| `edit_handler_module` | `edit_layout` | the `FormComponent` |
| `show_handler_module` | `show_layout` | the `ShowComponent` |

```elixir
defmodule MyAppWeb.ProductViews do
  use Aurora.Uix

  alias MyApp.Inventory
  alias MyApp.Inventory.Product

  auix_resource_metadata :product do
    context Inventory
    schema Product
    field :name, required: true
    field :description
    field :list_price
  end

  auix_create_ui do
    # Index handler for custom list behavior
    index_columns :product, [:name, :list_price],
      handler_module: MyApp.ProductIndexHandler

    # Edit handler for custom save logic
    edit_layout :product, edit_handler_module: MyApp.ProductFormHandler do
      inline [:name, :list_price, :description]
    end

    # Show handler for custom event handling
    show_layout :product, show_handler_module: MyApp.ProductShowHandler do
      inline [:name, :list_price, :description]
    end
  end
end
```

> #### Deprecated names {: .warning}
>
> `apply_action/2` and `save_entity/2` are the deprecated names of `auix_apply_action/2` and
> `auix_save_entity/2`, and are removed in 0.3. Until then an override of the old name still runs:
> the default `auix_*` callback calls it. Rename your overrides to the `auix_*` names.

### What a Handler Module Imports

`use` on a handler implementation brings in less than `use Phoenix.LiveView` does. Import the rest
in your module, as the examples below do:

| `use` | Brings in | Import or alias yourself |
|---|---|---|
| `IndexImpl` | `Phoenix.LiveView`, `Aurora.Uix.Templates.Basic.Helpers` (`assign_auix/3`, `auix_route_back/1`, …) and the `IndexImpl` alias | `Phoenix.Component` functions such as `assign/3` |
| `FormImpl` | the default callbacks only | the `FormImpl` alias, `assign/3`, `put_flash/3`, `push_navigate/2`, the helpers |
| `ShowComponentImpl` | the default callbacks only | the `ShowComponentImpl` alias, `assign/3`, `put_flash/3`, `push_navigate/2`, the helpers |

Functions the examples call that Aurora UIX does not define, such as `build_reference/1`, stand for
your own code.

A form or show handler runs in a LiveComponent, so it does not see the assigns of the parent
LiveView, such as `current_user`. Of those, it receives only the actor assign, when one is
configured (see [Ash Integration](ash_integration.md)).

## Callback Reference

### Index Handler Hook (LiveView)

`Aurora.Uix.Templates.Basic.Handlers.IndexImpl` handles the list pages and hosts the modals.

| Callback | Signature | Override it to |
|----------|-----------|----------------|
| `auix_mount/3` | `(map(), map(), Socket.t()) :: {:ok, Socket.t()}` | Initialize the socket, for example from the session |
| `auix_handle_params/3` | `(map(), binary(), Socket.t()) :: {:noreply, Socket.t()}` | Read URL parameters |
| `auix_handle_event/3` | `(binary(), map(), Socket.t()) :: {:noreply, Socket.t()}` | Answer your own events |
| `auix_handle_info/2` | `(term(), Socket.t()) :: {:noreply, Socket.t()}` | Process your own messages |
| `auix_handle_async/3` | `(atom(), term(), Socket.t()) :: {:noreply, Socket.t()}` | Receive the results of your own async tasks |
| `auix_apply_action/2` | `(Socket.t(), map()) :: Socket.t()` | Load data for a route action |

This handler answers an event, runs the work with `start_async/3` and receives the result:

```elixir
defmodule MyApp.ProductIndexHandler do
  use Aurora.Uix.Templates.Basic.Handlers.IndexImpl

  @impl IndexImpl
  def auix_handle_event("export", _params, socket) do
    {:noreply, start_async(socket, :export, fn -> MyApp.Inventory.export_products() end)}
  end

  def auix_handle_event(event, params, socket), do: super(event, params, socket)

  @impl IndexImpl
  def auix_handle_async(:export, {:ok, _result}, socket) do
    {:noreply, put_flash(socket, :info, "Export finished")}
  end

  def auix_handle_async(task, result, socket), do: super(task, result, socket)
end
```

Keep the `super` clauses: the index runs its own events, messages and async tasks through the same
callbacks. To read the list again after your own write, see
[Changing What the List Shows](liveview.md#changing-what-the-list-shows).

The `IndexComponent` has its own handler, which implements
`Aurora.Uix.Templates.Basic.Handlers.IndexComponentImpl`: `auix_update/2`, `auix_handle_event/3` and
`auix_handle_async/3`.

### Form/Edit Handler Hook (LiveComponent)

`Aurora.Uix.Templates.Basic.Handlers.FormImpl` handles create and edit. The Index LiveView hosts the
form in a modal; changes send `"validate"` and submitting sends `"save"`. After a save, the
component reports to the Index LiveView, which closes the modal and reads the list again.

| Callback | Signature | Override it to |
|----------|-----------|----------------|
| `auix_update/2` | `(map(), Socket.t()) :: {:ok, Socket.t()}` | Add assigns when the form loads or updates |
| `auix_handle_event/3` | `(binary(), map(), Socket.t()) :: {:noreply, Socket.t()}` | Answer your own events |
| `auix_save_entity/2` | `(Socket.t(), map()) :: {:ok, struct()} \| {:error, term()}` | Create or update the record your way |

`auix_save_entity/2` returns `{:ok, record}`, or `{:error, reason}` where `reason` is an
`Ecto.Changeset`, an Ash error or a message shown as the error flash:

```elixir
defmodule MyApp.ProductFormHandler do
  use Aurora.Uix.Templates.Basic.Handlers.FormImpl

  alias Aurora.Uix.Templates.Basic.Handlers.FormImpl

  # Customize creation logic
  @impl FormImpl
  def auix_save_entity(%{assigns: %{action: :new, auix: auix}} = _socket, entity_params) do
    # Add custom pre-processing
    entity_params = Map.put(entity_params, "reference", build_reference(entity_params))

    # Use context function to save
    case auix.modules.context.create_product(entity_params) do
      {:ok, product} ->
        # Custom post-creation logic
        notify_team(product)
        {:ok, product}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  # Customize update logic
  def auix_save_entity(%{assigns: %{action: action, auix: auix}} = _socket, entity_params)
      when action in [:edit, :show_edit] do
    # Custom validation before update
    if editable?(auix.entity) do
      auix.modules.context.update_product(auix.entity, entity_params)
    else
      {:error, "This product can no longer be edited"}
    end
  end
end
```

### Show Handler Hook (LiveComponent)

`Aurora.Uix.Templates.Basic.Handlers.ShowComponentImpl` handles the detail view.

| Callback | Signature | Override it to |
|----------|-----------|----------------|
| `auix_update/2` | `(map(), Socket.t()) :: {:ok, Socket.t()}` | Add assigns when the view loads or updates |
| `auix_handle_event/3` | `(binary(), map(), Socket.t()) :: {:noreply, Socket.t()}` | Answer your own events |

```elixir
defmodule MyApp.ProductShowHandler do
  use Aurora.Uix.Templates.Basic.Handlers.ShowComponentImpl

  alias Aurora.Uix.Templates.Basic.Handlers.ShowComponentImpl
  import Phoenix.LiveView, only: [put_flash: 3]
  import Aurora.Uix.Templates.Basic.Helpers, only: [auix_route_back: 1]

  @impl ShowComponentImpl
  def auix_handle_event("archive", _params, socket) do
    {:ok, _} = archive_product(socket.assigns.auix.entity)

    {:noreply,
     socket
     |> put_flash(:info, "Product archived")
     |> auix_route_back()}
  end

  # Default to standard implementation for switch_section, auix_download_upload, etc.
  def auix_handle_event(event, params, socket) do
    super(event, params, socket)
  end
end
```

### Overriding Phoenix Callbacks

Prefer the `auix_*` callbacks. The Phoenix callbacks under them are overridable too, for a change to
the lifecycle itself: `mount/3`, `handle_params/3`, `handle_event/3`, `handle_info/2` and
`handle_async/3` in the index, and `update/2` and `handle_event/3` in the form and show components
(the form handles `"save"` specially). Call `super`, or the default behavior is lost:

```elixir
defmodule MyApp.ProductIndexHandler do
  use Aurora.Uix.Templates.Basic.Handlers.IndexImpl

  import Phoenix.Component, only: [assign: 3]

  @impl Phoenix.LiveView
  def mount(params, session, socket) do
    case super(params, session, socket) do
      {:ok, socket} -> {:ok, assign(socket, :custom_data, load_custom_data())}
      error -> error
    end
  end
end
```

## Event Handling

Aurora UIX generates handlers for standard CRUD events. You can extend or override them in your custom handler modules using the `auix_handle_event/3` callback.

### Built-in Events

**Index LiveView:**
- `"delete"` - Delete entity
- `"auix_route_forward"` - Navigate forward with routing stack
- `"auix_route_back"` - Navigate back with routing stack
- `"filter-toggle"` - Toggle filters panel
- `"filters-clear"` - Clear all filters
- `"filters-submit"` - Apply filters
- `"index-sort"` - Sort the index. Sent by the sortable column headers with the field `"key"`: each click moves the sort through ascending, descending and back to the backend order. The card view's sort select and sort menu instead send `"sort"` as a field key, or `""` to return to the backend order; a newly chosen field keeps the current direction. Ignored when the layout option `sort_disabled?` is `true`
- `"index-sort-direction"` - Change the direction of the active sort. The card view's direction switch sends no parameter and reverses it; the card view's sort menu sends `"direction"` as `"asc"` or `"desc"` and sets it, and any other value is ignored. A no-op without an active sort, and ignored when `sort_disabled?` is `true`
- `"index-layout-change"` - Handles filter-form changes and row selection (matched via
  the `_target` field, e.g. `"selected_check__"` / `"selected_in_page__"` prefixes)
- `"selected-toggle_all"` - Select all matching rows across the whole result set (async)
- `"selected-cancel_toggle_all"` - Cancel an in-progress "select all" operation
- `"selected-delete_all"` - Delete all selected rows (async)
- `"pagination_to_page"` - Navigate to a specific page
- `"pagination_previous"` - Navigate to the previous page
- `"pagination_next"` - Navigate to the next page
- `"read_indexed_entry"` - Open the previous or next record from the open form or show view

**FormComponent (LiveComponent):**
- `"validate"` - Form validation on field change
- `"save"` - Save entity (create/update), handled specially outside `auix_handle_event/3`
- `"switch_section"` - Switch between tabs/sections in forms
- `"auix_route_back"` - Navigate back with routing stack
- `"auix_cancel_upload"` - Cancel an in-progress file upload
- `"auix_download_upload"` - Download a previously uploaded file
- `"auix_request_close"` - Close request from the form modal (× button, `Esc`, click outside); closes the modal, or opens the discard-changes dialog when the form has unsaved changes
- `"auix_keep_editing"` - Close the discard-changes dialog and keep the form open
- `"auix_discard_changes"` - Drop the unsaved changes and close the form modal

**ShowComponent (LiveComponent):**
- `"switch_section"` - Switch between tabs/sections in show view
- `"auix_download_upload"` - Download a previously uploaded file
- `"auix_open"` and `"auix_route_back"` - Sent by the Edit and Back actions when the show view is
  embedded as a [reusable component](components.md)

An event that neither your clauses nor the defaults handle raises. When you override
`auix_handle_event/3`, end it with a clause that calls `super`, so the built-in events keep working.

### Targeting the Component

The form and the show view are LiveComponents, so an event sent from a custom renderer or action reaches the
parent LiveView unless it names the component. Both handlers set `@auix._myself` to the component's `@myself`
for that:

```elixir
def archive_button(assigns) do
  ~H"""
  <button type="button" phx-click="archive" phx-target={@auix._myself}>Archive</button>
  """
end

# or, from a Phoenix.LiveView.JS command
JS.push("archive", target: @auix._myself)
```

The event is handled by the `auix_handle_event/3` of the form or show handler, as in the examples above.
`@auix._myself` exists in the index, the form and the show view. An untargeted event in the generated index
still reaches the Index LiveView and its `auix_handle_event/3`.

### Hiding Fields at Runtime

A form or show handler hides fields for one entity by assigning `:fields_to_reject`, a list of field keys. The
renderer skips them, in any group or section:

```elixir
defmodule MyApp.ProductFormHandler do
  use Aurora.Uix.Templates.Basic.Handlers.FormImpl

  alias Aurora.Uix.Templates.Basic.Handlers.FormImpl
  import Aurora.Uix.Templates.Basic.Helpers, only: [assign_auix: 3]

  @impl FormImpl
  def auix_update(assigns, socket) do
    {:ok, socket} = super(assigns, socket)

    {:ok, assign_auix(socket, :fields_to_reject, [:internal_notes])}
  end
end
```

Use the `hidden` and `omitted` field options when the field is hidden for every entity.

### What Is Internal

Besides the callbacks, a handler may rely on these `auix` assigns:

| Assign | Content |
|---|---|
| `entity` | the record of the open form or show view |
| `modules` | the modules of the resource, such as `modules.context` |
| `source_key` | the name of the primary index stream |
| `selection` | the selected rows of the index (`%Aurora.Uix.Selection{}`) |
| `navigation`, `uri_path`, `uri_path_id`, `routing_stack`, `index_new_link` | the [navigation state](liveview.md#navigation) |
| `layout_tree`, `load_items_options` | the [index query](liveview.md#scoping-the-index-query-at-runtime) |
| `fields_to_reject` | fields hidden at runtime |
| `_myself` | the event target of a component |

The others, such as `:index_layout_form`, `:filters_selected_count`, `:query_options` and
`:read_items`, are internal and can change in any release. The `auix-*` CSS classes and the
`name` and `id` attributes of the generated markup, such as `auix-delete-*`, follow the semi-public policy of the
[styling guide](../customization/styling.md#escape-hatch-semantic-class-overrides): they can change in any
release, and the change is listed in the CHANGELOG.

## Related guides

- [LiveView Integration](liveview.md) — the generated modules, streams and navigation
- [Live Updates](live_updates.md) — messages about data changes
- [Custom Actions](../customization/custom_actions.md) — the buttons and links that fire the events you handle here
- [Reusable Components](components.md) — embedding the views in your own LiveView
