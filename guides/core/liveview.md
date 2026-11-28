# LiveView Integration

Aurora UIX leverages Phoenix LiveView to provide dynamic, real-time CRUD interfaces. The framework generates fully-functional LiveView and LiveComponent modules at compile time, handling all the boilerplate while remaining customizable.

> #### JavaScript setup required {: .warning}
> Aurora UIX requires its client-side hooks to be imported in your `app.js`. Without this, features
> like file downloads and the theme switcher will not work. See
> [JavaScript Setup](../introduction/getting_started.md#javascript-setup) in the Getting Started
> guide.

## How It Works

### Module Generation with `auix_create_ui`

The `auix_create_ui/0` macro generates a complete set of modules for your resource. For a resource named `product`, it creates:

```
Overview.Product                      # Parent module (generated)
├── Overview.Product.Index            # LiveView - Lists the records, owns the routes
├── Overview.Product.IndexComponent   # LiveComponent - Handles the list
├── Overview.Product.FormComponent    # LiveComponent - Handles create/edit forms
└── Overview.Product.ShowComponent    # LiveComponent - Handles detail view display
```

#### Generated Module Structure

**Index Module** (`Overview.Product.Index`) - LiveView:
- Lists entities with streaming for performance
- Manages filtering, sorting, and pagination
- Handles delete operations with confirmation
- Hosts modal containers for form and show components
- Provides navigation between list and detail views
- Implements LiveView callbacks: `mount/3`, `handle_params/3`, `handle_event/3`, `handle_info/2`, `handle_async/3`

**IndexComponent Module** (`Overview.Product.IndexComponent`) - LiveComponent:
- Holds the state of an embedded list: streams, filters, sort, pagination and selection
- Can be embedded in any LiveView; see [Reusable Components](components.md)

**FormComponent Module** (`Overview.Product.FormComponent`) - LiveComponent:
- Renders create and edit forms in modals
- Handles form validation and submission
- Manages form state and changesets
- Handles section/tab switching in forms
- Implements LiveComponent callbacks: `update/2`, `handle_event/3`

**ShowComponent Module** (`Overview.Product.ShowComponent`) - LiveComponent:
- Displays entity details in modals or dedicated pages
- Renders read-only entity information
- Manages section/tab switching in show views
- Provides edit navigation
- Implements LiveComponent callbacks: `update/2`, `handle_event/3`

## Customizing Behavior

### Handler Hooks

Aurora UIX uses a handler delegation pattern. The generated modules delegate to handler implementation modules that provide the actual logic. You can customize specific behaviors by providing your own handler modules.

Handler hooks are specified directly in the layout DSL as options:
- **`handler_module`** - For index columns (Index LiveView handler)
- **`edit_handler_module`** - For edit layout (FormComponent handler)
- **`show_handler_module`** - For show layout (ShowComponent handler)

> #### Deprecated names {: .warning}
>
> `apply_action/2` and `save_entity/2` are the deprecated names of `auix_apply_action/2` and
> `auix_save_entity/2`, and are removed in 0.3. Until then an override of the old name still runs:
> the default `auix_*` callback calls it. Rename your overrides to the `auix_*` names.

### Understanding Aurora UIX Callbacks vs Phoenix Callbacks

Aurora UIX provides two layers of callbacks:

**1. Aurora UIX Callbacks (`auix_*`)** - Business logic customization:
- Prefixed with `auix_` (e.g., `auix_mount`, `auix_handle_event`)
- Implement Aurora UIX-specific behavior
- Recommended for most customizations
- Easier to extend without breaking the framework's internal logic

**2. Phoenix Callbacks** - Protocol implementation:
- Standard Phoenix.LiveView or Phoenix.LiveComponent callbacks
- Available for advanced customizations
- Require careful handling to maintain framework functionality
- All marked as `defoverridable` for flexibility

**When to override which:**
- **Override `auix_*` callbacks** when you want to customize Aurora UIX behavior (filtering, actions, data loading)
- **Override Phoenix callbacks** only when you need to fundamentally change how the component works

### What a Handler Module Imports

`use` on a handler implementation brings in less than `use Phoenix.LiveView` does. Import the rest
in your module, as the examples below do:

| `use` | Brings in | Import or alias yourself |
|---|---|---|
| `IndexImpl` | `Phoenix.LiveView`, `Aurora.Uix.Templates.Basic.Helpers` (`assign_auix/3`, `auix_route_back/1`, …) and the `IndexImpl` alias | `Phoenix.Component` functions such as `assign/3` |
| `FormImpl` | the default callbacks only | the `FormImpl` alias, `assign/3`, `put_flash/3`, `push_navigate/2`, the helpers |
| `ShowComponentImpl` | the default callbacks only | the `ShowComponentImpl` alias, `assign/3`, `put_flash/3`, `push_navigate/2`, the helpers |

Functions the examples call that Aurora UIX does not define, such as `load_user/1`, stand for your
own code.

A form or show handler runs in a LiveComponent, so it does not see the assigns of the parent
LiveView, such as `current_user`. Of those, it receives only the actor assign, when one is
configured (see [Ash Integration](ash_integration.md)).

### Index Handler Hook (LiveView)

The Index handler manages the Index LiveView for list pages and hosting modals.

**Available Callbacks:**

| Callback | Type | Purpose |
|----------|------|---------|
| `auix_mount/3` | IndexImpl | Initialize LiveView socket |
| `auix_handle_params/3` | IndexImpl | Handle URL parameter changes |
| `auix_handle_event/3` | IndexImpl | Handle custom events |
| `auix_handle_info/2` | IndexImpl | Handle info messages |
| `auix_handle_async/3` | IndexImpl | Handle async task results |
| `auix_apply_action/2` | IndexImpl | Apply route actions |

**Example - Override `auix_mount/3`:**

```elixir
defmodule MyApp.ProductIndexHandler do
  use Aurora.Uix.Templates.Basic.Handlers.IndexImpl

  import Phoenix.Component, only: [assign: 3]

  # Override mount to add custom initialization
  @impl IndexImpl
  def auix_mount(params, session, socket) do
    socket
    |> assign(:current_user, load_user(session))
    |> assign(:preferences, load_preferences(session))
    |> then(&super(params, session, &1))
  end
end
```

**Example - Override `auix_handle_params/3`:**

```elixir
defmodule MyApp.ProductIndexHandler do
  use Aurora.Uix.Templates.Basic.Handlers.IndexImpl

  import Phoenix.Component, only: [assign: 3]

  @impl IndexImpl
  def auix_handle_params(params, url, socket) do
    # Add custom logic before standard parameter handling
    socket = assign(socket, :custom_filter, params["filter"])
    
    # Call default implementation
    super(params, url, socket)
  end
end
```

**Example - Override `auix_handle_event/3`:**

```elixir
defmodule MyApp.ProductIndexHandler do
  use Aurora.Uix.Templates.Basic.Handlers.IndexImpl

  @impl IndexImpl
  def auix_handle_event("bulk_publish", %{"ids" => ids}, socket) do
    # Custom bulk operation
    Enum.each(ids, &publish_product/1)
    Aurora.Uix.Events.changed(MyApp.Inventory.Product)

    {:noreply, put_flash(socket, :info, "Products published")}
  end

  def auix_handle_event(event, params, socket) do
    super(event, params, socket)
  end
end
```

**Example - Override `auix_handle_info/2`:**

```elixir
defmodule MyApp.ProductIndexHandler do
  use Aurora.Uix.Templates.Basic.Handlers.IndexImpl

  @impl IndexImpl
  def auix_handle_info({:notification, message}, socket) do
    {:noreply, put_flash(socket, :info, message)}
  end

  def auix_handle_info(message, socket) do
    super(message, socket)
  end
end
```

**Example - Override `auix_handle_async/3`:**

```elixir
defmodule MyApp.ProductIndexHandler do
  use Aurora.Uix.Templates.Basic.Handlers.IndexImpl

  import Phoenix.Component, only: [assign: 3]

  @impl IndexImpl
  def auix_handle_async(:custom_export, {:ok, result}, socket) do
    {:noreply, assign(socket, :export_result, result)}
  end

  def auix_handle_async(task, result, socket) do
    super(task, result, socket)
  end
end
```

**Example - Override `auix_apply_action/2`:**

```elixir
defmodule MyApp.ProductIndexHandler do
  use Aurora.Uix.Templates.Basic.Handlers.IndexImpl

  import Phoenix.Component, only: [assign: 3]

  @impl IndexImpl
  def auix_apply_action(socket, params) do
    socket
    |> super(params)
    |> maybe_load_additional_data(socket.assigns.live_action)
  end

  defp maybe_load_additional_data(socket, :show) do
    assign(socket, :related_products, fetch_related())
  end

  defp maybe_load_additional_data(socket, _action), do: socket
end
```

### Form/Edit Handler Hook (LiveComponent)

The FormComponent handler manages the LiveComponent for create and edit operations.

**Available Callbacks:**

| Callback | Type | Purpose |
|----------|------|---------|
| `auix_update/2` | FormImpl | Initialize/update component state |
| `auix_handle_event/3` | FormImpl | Handle custom events |
| `auix_save_entity/2` | FormImpl | Create or update entity |

**Example - Override `auix_update/2`:**

```elixir
defmodule MyApp.ProductFormHandler do
  use Aurora.Uix.Templates.Basic.Handlers.FormImpl

  alias Aurora.Uix.Templates.Basic.Handlers.FormImpl
  import Phoenix.Component, only: [assign: 3]

  @impl FormImpl
  def auix_update(assigns, socket) do
    socket
    |> assign(:form_metadata, load_metadata())
    |> assign(:templates, load_templates())
    |> then(&super(assigns, &1))
  end
end
```

**Example - Override `auix_save_entity/2`:**

`auix_save_entity/2` returns `{:ok, record}`, or `{:error, reason}` where `reason` is an
`Ecto.Changeset`, an Ash error or a message shown as the error flash.

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

**Example - Override `auix_handle_event/3`:**

```elixir
defmodule MyApp.ProductFormHandler do
  use Aurora.Uix.Templates.Basic.Handlers.FormImpl

  alias Aurora.Uix.Templates.Basic.Handlers.FormImpl
  import Phoenix.Component, only: [assign: 3]

  @impl FormImpl
  def auix_handle_event("load_template", %{"id" => template_id}, socket) do
    template = load_template(template_id)
    {:noreply, populate_form(socket, template)}
  end

  def auix_handle_event("calculate_totals", params, socket) do
    totals = calculate_form_totals(params)
    {:noreply, assign(socket, :totals, totals)}
  end

  # Default to standard implementation for validate, save, etc.
  def auix_handle_event(event, params, socket) do
    super(event, params, socket)
  end
end
```

### Show Handler Hook (LiveComponent)

The ShowComponent handler manages the LiveComponent for detail views.

**Available Callbacks:**

| Callback | Type | Purpose |
|----------|------|---------|
| `auix_update/2` | ShowComponentImpl | Initialize/update component state |
| `auix_handle_event/3` | ShowComponentImpl | Handle custom events |

**Example - Override `auix_update/2`:**

```elixir
defmodule MyApp.ProductShowHandler do
  use Aurora.Uix.Templates.Basic.Handlers.ShowComponentImpl

  alias Aurora.Uix.Templates.Basic.Handlers.ShowComponentImpl
  import Phoenix.Component, only: [assign: 3]

  @impl ShowComponentImpl
  def auix_update(assigns, socket) do
    socket
    |> assign(:analytics, load_analytics(assigns.auix.entity))
    |> assign(:related_items, load_related(assigns.auix.entity))
    |> then(&super(assigns, &1))
  end
end
```

**Example - Override `auix_handle_event/3`:**

```elixir
defmodule MyApp.ProductShowHandler do
  use Aurora.Uix.Templates.Basic.Handlers.ShowComponentImpl

  alias Aurora.Uix.Templates.Basic.Handlers.ShowComponentImpl
  import Phoenix.LiveView, only: [put_flash: 3, push_navigate: 2]
  import Aurora.Uix.Templates.Basic.Helpers, only: [auix_route_back: 1]

  @impl ShowComponentImpl
  def auix_handle_event("duplicate", _params, socket) do
    product = socket.assigns.auix.entity
    {:ok, new_product} = duplicate_product(product)
    
    {:noreply,
     socket
     |> put_flash(:info, "Product duplicated")
     |> push_navigate(to: "/products/#{new_product.id}/edit")}
  end

  def auix_handle_event("export_pdf", _params, socket) do
    generate_pdf(socket.assigns.auix.entity)
    {:noreply, put_flash(socket, :info, "PDF generated")}
  end

  def auix_handle_event("archive", _params, socket) do
    product = socket.assigns.auix.entity
    {:ok, _} = archive_product(product)
    
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

### Specifying Handler Hooks in Layout DSL

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

`component_handler_module:` on `index_columns` sets the handler of the `IndexComponent`. It implements
`Aurora.Uix.Templates.Basic.Handlers.IndexComponentImpl`: `auix_update/2`, `auix_handle_event/3` and
`auix_handle_async/3`.

### Advanced: Overriding Phoenix Callbacks

While Aurora UIX callbacks (`auix_*`) are recommended for most customizations, you can also override the underlying Phoenix.LiveView or Phoenix.LiveComponent callbacks for advanced use cases.

**⚠️ Important Notes:**
- Overriding Phoenix callbacks bypasses Aurora UIX's internal logic
- You must ensure all framework functionality is preserved
- Use `super/2` to call the default implementation when appropriate
- All Phoenix callbacks are marked as `defoverridable`

**Example - Override Phoenix.LiveView `mount/3` (Index):**

```elixir
defmodule MyApp.ProductIndexHandler do
  use Aurora.Uix.Templates.Basic.Handlers.IndexImpl

  import Phoenix.Component, only: [assign: 3]

  # This bypasses auix_mount completely
  @impl Phoenix.LiveView
  def mount(params, session, socket) do
    # Must replicate all Aurora UIX initialization
    # or call super to get default behavior first
    case super(params, session, socket) do
      {:ok, socket} ->
        # Add your custom logic
        {:ok, assign(socket, :custom_data, load_custom_data())}
      error -> error
    end
  end
end
```

**Example - Override Phoenix.LiveComponent `update/2` (Form):**

```elixir
defmodule MyApp.ProductFormHandler do
  use Aurora.Uix.Templates.Basic.Handlers.FormImpl

  alias Aurora.Uix.Templates.Basic.Handlers.FormImpl
  import Phoenix.Component, only: [assign: 3]

  # This bypasses auix_update completely
  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    # Must call super or replicate all Aurora UIX logic
    case super(assigns, socket) do
      {:ok, socket} ->
        # Add your custom logic
        {:ok, assign(socket, :form_templates, load_templates())}
      error -> error
    end
  end
end
```

**When to use Phoenix callbacks:**
- You need to fundamentally change component lifecycle
- You're integrating with non-Aurora UIX functionality
- You need fine-grained control over socket assigns before Aurora UIX processing

**When to use Aurora UIX callbacks (recommended):**
- Adding custom business logic
- Modifying data loading or filtering
- Adding custom event handlers
- Extending functionality while preserving framework behavior

### Event Handling

Aurora UIX generates handlers for standard CRUD events. You can extend or override them in your custom handler modules using the `auix_handle_event/3` callback.

#### Built-in Events

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

#### Adding Custom Events

Custom events are handled through the `auix_handle_event/3` callback in each handler.

**In Index Handler:**

```elixir
defmodule MyApp.ProductIndexHandler do
  use Aurora.Uix.Templates.Basic.Handlers.IndexImpl

  @impl IndexImpl
  def auix_handle_event("publish", %{"id" => id}, socket) do
    product = socket.assigns.auix.modules.context.get_product(id)
    {:ok, published} = socket.assigns.auix.modules.context.publish_product(product)
    Aurora.Uix.Events.updated(published)

    {:noreply, put_flash(socket, :info, "Product published")}
  end

  def auix_handle_event(event, params, socket) do
    super(event, params, socket)
  end
end
```

**In FormComponent Handler:**

```elixir
defmodule MyApp.ProductFormHandler do
  use Aurora.Uix.Templates.Basic.Handlers.FormImpl

  alias Aurora.Uix.Templates.Basic.Handlers.FormImpl
  import Phoenix.Component, only: [assign: 3]

  # Custom events in forms use auix_handle_event
  @impl FormImpl
  def auix_handle_event("preview", _params, socket) do
    # Custom preview logic
    {:noreply, assign(socket, :preview_mode, true)}
  end

  def auix_handle_event("calculate_totals", params, socket) do
    # Custom calculation logic
    totals = calculate_form_totals(params)
    {:noreply, assign(socket, :totals, totals)}
  end

  # Let FormImpl handle standard events (validate, save, switch_section)
  def auix_handle_event(event, params, socket) do
    super(event, params, socket)
  end
end
```

**In ShowComponent Handler:**

```elixir
defmodule MyApp.ProductShowHandler do
  use Aurora.Uix.Templates.Basic.Handlers.ShowComponentImpl

  alias Aurora.Uix.Templates.Basic.Handlers.ShowComponentImpl
  import Phoenix.Component, only: [assign: 3]
  import Phoenix.LiveView, only: [put_flash: 3]

  # Custom events in show views use auix_handle_event
  @impl ShowComponentImpl
  def auix_handle_event("export", _params, socket) do
    # Custom export logic
    export_data(socket.assigns.auix.entity)
    {:noreply, put_flash(socket, :info, "Export started")}
  end

  def auix_handle_event("print", _params, socket) do
    # Custom print logic
    {:noreply, assign(socket, :print_mode, true)}
  end

  # Let ShowComponentImpl handle standard events (switch_section, auix_download_upload)
  def auix_handle_event(event, params, socket) do
    super(event, params, socket)
  end
end
```

<a id="targeting-the-component"></a>

#### Targeting the Component

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

#### Hiding Fields at Runtime

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

#### What Is Internal

Besides the callbacks, a handler may rely on these `auix` assigns:

| Assign | Content |
|---|---|
| `entity` | the record of the open form or show view |
| `modules` | the modules of the resource, such as `modules.context` |
| `source_key` | the name of the primary index stream |
| `selection` | the selected rows of the index (`%Aurora.Uix.Selection{}`) |
| `navigation`, `uri_path`, `uri_path_id`, `routing_stack`, `index_new_link` | the [navigation state](#navigation) |
| `layout_tree`, `load_items_options` | the [index query](#scoping-the-index-query-at-runtime) |
| `fields_to_reject` | fields hidden at runtime |
| `_myself` | the event target of a component |

The others, such as `:index_layout_form`, `:filters_selected_count`, `:query_options` and
`:read_items`, are internal and can change in any release. The `auix-*` CSS classes and the
`name` and `id` attributes of the generated markup, such as `auix-delete-*`, follow the semi-public policy of the
[styling guide](../customization/styling.md#escape-hatch-semantic-class-overrides): they can change in any
release, and the change is listed in the CHANGELOG.

## Reacting to Data Changes

When the host names a PubSub server, every data change made through a generated UI is
published, and every open index over the same schema re-reads its current page. Other browser
sessions see a save or a delete without reloading.

### Enabling

```elixir
# config/config.exs
config :aurora_uix, pubsub_server: MyApp.PubSub
```

Name a `Phoenix.PubSub` server your application already supervises; Aurora UIX starts no
process. With the key unset, nothing is subscribed or broadcast, and every view behaves as
before: only the session that made a change refreshes.

### Topics and events

Each schema (or Ash resource) has one topic, `"auix:" <> inspect(schema)` — for example
`auix:MyApp.Inventory.Product`. `Aurora.Uix.Events.topic/1` builds it.

Every message on a topic is an `%Aurora.Uix.Event{}`:

| Field | Content |
|---|---|
| `schema` | the schema or Ash resource module |
| `action` | `:created`, `:updated`, `:deleted` or `:changed` |
| `ids` | primary-key values of the affected records; `[]` for `:changed` |
| `entities` | the written records when the publisher has them, else `[]` |

`:changed` means the data changed in a way that cannot be listed record by record (a bulk
update, an import).

The generated UI publishes:

| Action | Event |
|---|---|
| Form save of a new record | `:created` |
| Form save of an existing record (edit, show-edit) | `:updated` |
| Row delete | `:deleted` |
| One-to-many child row delete | `:deleted`, on the child's schema |
| "Delete selected" | one `:deleted` listing only the records actually deleted |

Embeds and many-to-many changes are saved through the parent form, so they publish the
parent's `:updated`. The view that made a change does not receive its own event: it refreshes
locally, as it always has.

### How an open index reacts

| On screen | Reaction |
|---|---|
| The list | Deleted ids leave the selection, then the current page is re-read with the viewer's own filters, sort, page and actor. |
| Show of an affected record | `:updated` re-reads the record; `:deleted` closes the view with the flash "Item deleted successfully". |
| Form on an affected record | The form keeps what the user typed; a flash reports the change. |

The list is always re-read, never patched from the event's `entities`, so Ash policies and
layout `where` conditions still apply to what each viewer sees.

The reactions are `auix_handle_info/2` clauses. An override of `auix_handle_info/2` must pass
every message it does not handle to `super`, as the `auix_handle_info/2` example under
[Index Handler Hook](#index-handler-hook-liveview) does.

### Publishing from host code

Any process can publish: a custom action, a background job, another LiveView.

```elixir
alias Aurora.Uix.Events

Events.created(product)                               # schema taken from the record
Events.updated(product)
Events.deleted(MyApp.Inventory.Product, [product.id])
Events.changed(MyApp.Inventory.Product)
```

A publisher returns what `Phoenix.PubSub.broadcast/3` returns, and `:ok` without broadcasting
when `pubsub_server` is not configured.

### Subscribing from host code

```elixir
def mount(_params, _session, socket) do
  if connected?(socket), do: Aurora.Uix.Events.subscribe(MyApp.Inventory.Product)
  {:ok, socket}
end

def handle_info(%Aurora.Uix.Event{action: :created}, socket) do
  {:noreply, put_flash(socket, :info, "A product was added")}
end

# The topic also carries :updated, :deleted and :changed
def handle_info(%Aurora.Uix.Event{}, socket), do: {:noreply, socket}
```

Subscribe once per schema: each call to `subscribe/1` adds a subscription, and each subscription
delivers the event again. `Aurora.Uix.Events.unsubscribe(MyApp.Inventory.Product)` stops the
messages, for example when a LiveView changes the schema it watches. With `pubsub_server` not
configured, both calls do nothing and return `:ok`.

### Index commands

Two requests are not data changes, so they are messages to one index LiveView process, never
broadcasts:

| Function | Effect |
|---|---|
| `Aurora.Uix.Events.refresh(pid \\ self())` | re-reads the current page |
| `Aurora.Uix.Events.reset_selection(pid \\ self())` | clears the selection, then re-reads the current page |

A handler running inside the index calls them with no argument. A task or job that holds the
index LiveView's pid passes it. Both work whether or not `pubsub_server` is configured.

## Callback Reference

### Index LiveView Callbacks

The Index module is a full Phoenix LiveView with Aurora UIX callbacks for customization.

#### Aurora UIX Callbacks (IndexImpl)

| Callback | Signature | Purpose | When to Override |
|----------|-----------|---------|------------------|
| `auix_mount/3` | `(map(), map(), Socket.t()) :: {:ok, Socket.t()}` | Initialize socket | Add custom initialization, load session data |
| `auix_handle_params/3` | `(map(), binary(), Socket.t()) :: {:noreply, Socket.t()}` | Handle URL changes | Custom routing logic, filter extraction |
| `auix_handle_event/3` | `(binary(), map(), Socket.t()) :: {:noreply, Socket.t()}` | Handle events | Add custom event handlers |
| `auix_handle_info/2` | `(term(), Socket.t()) :: {:noreply, Socket.t()}` | Handle messages | Process custom info messages |
| `auix_handle_async/3` | `(atom(), term(), Socket.t()) :: {:noreply, Socket.t()}` | Handle async results | Process custom async task results |
| `auix_apply_action/2` | `(Socket.t(), map()) :: Socket.t()` | Apply route actions | Load action-specific data |

```elixir
@callback auix_mount(params :: map(), session :: map(), socket :: Socket.t()) ::
            {:ok, Socket.t()}
@callback auix_handle_params(params :: map(), url :: binary(), socket :: Socket.t()) ::
            {:noreply, Socket.t()}
@callback auix_handle_event(event :: binary(), params :: map(), socket :: Socket.t()) ::
            {:noreply, Socket.t()}
@callback auix_handle_info(message :: term(), socket :: Socket.t()) ::
            {:noreply, Socket.t()}
@callback auix_handle_async(task :: atom(), result :: term(), socket :: Socket.t()) ::
            {:noreply, Socket.t()}
@callback auix_apply_action(socket :: Socket.t(), params :: map()) :: Socket.t()
```

#### Phoenix.LiveView Callbacks (Advanced)

All standard Phoenix.LiveView callbacks are overridable for advanced use cases:

| Callback | Signature |
|----------|-----------|
| `mount/3` | `(map(), map(), Socket.t()) :: {:ok, Socket.t()}` |
| `handle_params/3` | `(map(), binary(), Socket.t()) :: {:noreply, Socket.t()}` |
| `handle_event/3` | `(binary(), map(), Socket.t()) :: {:noreply, Socket.t()}` |
| `handle_info/2` | `(term(), Socket.t()) :: {:noreply, Socket.t()}` |
| `handle_async/3` | `(atom(), term(), Socket.t()) :: {:noreply, Socket.t()}` |

### FormComponent Callbacks

The FormComponent is a Phoenix.LiveComponent with Aurora UIX callbacks for customization.

#### Aurora UIX Callbacks (FormImpl)

| Callback | Signature | Purpose | When to Override |
|----------|-----------|---------|------------------|
| `auix_update/2` | `(map(), Socket.t()) :: {:ok, Socket.t()}` | Initialize/update component | Add metadata, load templates |
| `auix_handle_event/3` | `(binary(), map(), Socket.t()) :: {:noreply, Socket.t()}` | Handle custom events | Add custom form interactions |
| `auix_save_entity/2` | `(Socket.t(), map()) :: {:ok, struct()} \| {:error, term()}` | Save/update entity | Custom validation, authorization, side effects |

```elixir
@callback auix_update(assigns :: map(), socket :: Socket.t()) :: {:ok, Socket.t()}
@callback auix_handle_event(event :: binary(), params :: map(), socket :: Socket.t()) ::
            {:noreply, Socket.t()}
@callback auix_save_entity(socket :: Socket.t(), entity_params :: map()) ::
            {:ok, struct()} | {:error, term()}
```

#### Phoenix.LiveComponent Callbacks (Advanced)

| Callback | Signature |
|----------|-----------|
| `update/2` | `(map(), Socket.t()) :: {:ok, Socket.t()}` |
| `handle_event/3` | `(binary(), map(), Socket.t()) :: {:noreply, Socket.t()}` (note: `"save"` is handled specially) |

### ShowComponent Callbacks

The ShowComponent is a Phoenix.LiveComponent with Aurora UIX callbacks for customization.

#### Aurora UIX Callbacks (ShowComponentImpl)

| Callback | Signature | Purpose | When to Override |
|----------|-----------|---------|------------------|
| `auix_update/2` | `(map(), Socket.t()) :: {:ok, Socket.t()}` | Initialize/update component | Load analytics, related data |
| `auix_handle_event/3` | `(binary(), map(), Socket.t()) :: {:noreply, Socket.t()}` | Handle custom events | Add custom show view actions |

```elixir
@callback auix_update(assigns :: map(), socket :: Socket.t()) :: {:ok, Socket.t()}
@callback auix_handle_event(event :: binary(), params :: map(), socket :: Socket.t()) ::
            {:noreply, Socket.t()}
```

#### Phoenix.LiveComponent Callbacks (Advanced)

| Callback | Signature |
|----------|-----------|
| `update/2` | `(map(), Socket.t()) :: {:ok, Socket.t()}` |
| `handle_event/3` | `(binary(), map(), Socket.t()) :: {:noreply, Socket.t()}` |

## Form Handling

Aurora UIX automatically generates forms based on your resource metadata. Forms are rendered by the FormComponent LiveComponent and handled through the `"validate"` and `"save"` events.

### How Forms Work

1. **Index LiveView** hosts the FormComponent in a modal
2. **FormComponent** receives entity data and renders the form
3. User interactions trigger `"validate"` events for real-time validation
4. Form submission triggers `"save"` event
5. FormComponent saves data and notifies Index LiveView
6. Index LiveView closes modal and refreshes data

### Customizing Form Behavior

See the **FormComponent Callbacks** section above for details on overriding `auix_update/2`, `auix_handle_event/3`, and `auix_save_entity/2`.

## Working with Streams

The index lists its records in LiveView streams and manages them for you.

### Stream Naming

- **Primary stream** - Named by `auix.source_key` (e.g., `:products` for a product index)
- **Alternate streams** - For other views of the same records, named with the string
  `"#{source_key}__#{suffix}"`, where each suffix comes from the `:alternate_streams_suffixes`
  layout option (default: `["mobile"]`, giving `"products__mobile"`). Suffixes are arbitrary,
  host-defined strings, not built-in view types — configure additional ones
  (e.g. `"card"`, `"calendar"`) to fit your own alternate layouts.

For how the list pages and scrolls, see
[Pagination and Infinite Scroll](layouts.md#pagination-and-infinite-scroll).

### Changing What the List Shows

A stream item is not the record itself: it is the record as a plain map, with keys the library adds
for selection and row striping. Do not insert records into these streams yourself. Write the data,
then let the index read its page again:

```elixir
defmodule MyApp.ProductIndexHandler do
  use Aurora.Uix.Templates.Basic.Handlers.IndexImpl

  alias Aurora.Uix.Events

  @impl IndexImpl
  def auix_handle_event("restock", %{"id" => id}, socket) do
    {:ok, _product} = MyApp.Inventory.restock_product(id)
    Events.refresh()

    {:noreply, socket}
  end

  def auix_handle_event(event, params, socket), do: super(event, params, socket)
end
```

`Events.refresh/0` re-reads the page of this view. To update every open index, publish the change
instead (see [Publishing from host code](#publishing-from-host-code)).

## Filtering and Sorting

Aurora UIX supports sorting via configuration in both resource metadata and layout DSL. Sorting is applied automatically and can be customized per view.

<div align="center">
    <img src="./images/features/index_in_use-desktop.png" width="600" alt="Product list with the filter bar open, the Name column sorted, two rows selected with a delete selected button, and the page bar under the rows"/>
</div>

### Configuring Default Sort Order

Set `order_by:` on the resource, on the `index_columns` layout, or both; the layout's value wins:

```elixir
auix_resource_metadata :product do
  context MyApp.Inventory
  schema MyApp.Inventory.Product
  order_by :reference
  field :name, required: true
end

auix_create_ui do
  index_columns :product, [:reference, :name], order_by: :name
end
```

The order is applied by the database query, and is replaced when the user sorts: a click on a
sortable column header (a second click reverses the direction, a third restores the backend order),
or, in the mobile card view, the sort control. A column opts out with the field option
`sortable?: false`; the layout option `sort_disabled?: true` turns user sorting off for the whole
index.

The accepted values of `order_by` and `where` are listed in
[Index Query Options](resource_metadata.md#index-query-options).

### Scoping the Index Query at Runtime

The index handler keeps the query of the list in `auix.load_items_options`, a keyword list. A custom
`IndexImpl` handler can read it and replace it with `assign_auix(socket, :load_items_options, ...)`.
Only these keys are read; any other is ignored:

| Key | Value |
|-----|-------|
| `:where` | A list of conditions, a map of equalities, a single condition or a dynamic expression |
| `:order_by` | The order of the entries |
| `:preload` | Associations to load besides the ones the layout renders |

The handler builds it from the resource's options, the index layout's options and the associations the
layout renders, each time it loads the list: on mount, on `auix_route_back` and when the items per page change.
Submitting the filters and changing the sort read it again, add the submitted filters and the sort to it, and reload
the list. Other reloads, such as a refresh after a save, reuse the query last built.

Choose where to set a `where` by how long it must last:

- **From the first load on**: in `mount/3`, before calling `super`, change the layout tree. It is read at every rebuild,
  so it lasts for the life of the view.

  ```elixir
  def mount(params, session, %{assigns: %{auix: auix}} = socket) do
    layout_tree = struct(auix.layout_tree, where: {:reference, :lt, "item_test-06"})

    super(params, session, assign_auix(socket, :layout_tree, layout_tree))
  end
  ```

- **After the list is loaded**: replace `load_items_options`. It applies from the next filter submit or sort change,
  and the next rebuild discards it. To last, also change the layout tree as above.

  ```elixir
  load_items_options =
    Keyword.put(auix.load_items_options, :where, [{:reference, :lt, "item_test-06"}])

  assign_auix(socket, :load_items_options, load_items_options)
  ```

The other query assigns of `auix` (`query_options`, `read_items`) are internal: they change between releases.

## Navigation

`Aurora.Uix.Navigation` describes the navigation of the generated LiveView as plain data. The state is
`@auix.navigation`, an `%Aurora.Uix.Navigation{}` with the base path, the current path and the routing stack.
The functions take that struct and return data.

| Function | Returns |
|---|---|
| `Navigation.path(nav, action, id)` | The path of `:index`, `:new`, `:show`, `:edit` or `:show_edit` |
| `Navigation.forward(nav, target)` | `{nav, route}`: `nav` has the current path pushed on the routing stack, and `route` leads to `target` (`patch: path` or `to: path`) |
| `Navigation.back(nav)` | `{nav, route}`: `nav` has the routing stack popped, and `route` leads back |

A route is `%{type: :patch | :navigate, path: path}`. Its path carries the routing stack in `routing_stack=`.

`auix_route_forward/2` calls `Navigation.forward/2` and `auix_route_back/1` calls `Navigation.back/1` on
`@auix.navigation`; each stores the returned struct and pushes the returned route. Use them in a handler:

```elixir
def auix_handle_event("archive", _params, socket) do
  {:noreply, auix_route_back(socket)}
end
```

The generated LiveView navigates with a patch for a change within the view, a navigate for another view,
and the routing stack in `?routing_stack=` so that back returns to where the user came from. The components
never navigate: they report to the LiveView that hosts them; see [Reusable Components](components.md).

`@auix.uri_path`, `@auix.uri_path_id`, `@auix.routing_stack` and `@auix[:index_new_link]` mirror the
navigation state and stay readable from custom actions.

## Performance Considerations

### Streams for Large Lists

Aurora UIX uses Phoenix LiveView streams for index views, which efficiently handle:
- Inserts/updates/deletes without full re-render
- Pagination for large datasets
- Lazy loading capabilities

### Preloading Associations

Association fields that a layout renders are preloaded with the entity, so there is no
per-field preload option to set. To load an association the layout does not render, list it in the
resource's or the index layout's `preload` (see
[Index Query Options](resource_metadata.md#index-query-options)).

An association field that names its resource with `resource:` also loads, for each related
record, the association fields that the layouts of the named resource render, one level deep.
Without `resource:` it loads the related records alone.

### Async Operations

Run heavy work with `start_async/3` and receive the result in `auix_handle_async/3`:

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

Keep the `super` clauses: the index runs its own events and async tasks through the same callbacks.

## Debugging

### Inspecting Socket Assigns

The `:auix` assign holds the configuration and the runtime state. To look at it, inspect it from a
handler:

```elixir
defmodule MyApp.ProductIndexHandler do
  use Aurora.Uix.Templates.Basic.Handlers.IndexImpl

  @impl IndexImpl
  def auix_mount(params, session, socket) do
    {:ok, socket} = super(params, session, socket)
    IO.inspect(Map.keys(socket.assigns.auix), label: "auix")

    {:ok, socket}
  end
end
```

### LiveView DevTools

The generated views are ordinary LiveViews, so
[Phoenix LiveDashboard](https://hexdocs.pm/phoenix_live_dashboard) shows their processes like any
other. Applications created with `mix phx.new` serve it at `/dev/dashboard`.

## Best Practices

1. **Keep handlers focused** - One concern per handler module
2. **Use streams** - Always use streams for list views instead of assigning the full list
3. **Validate early** - Validate inputs in `handle_event` before database operations
4. **Handle errors gracefully** - Provide user feedback for all operations
5. **Preload data** - Configure preloads to avoid N+1 queries
6. **Test in isolation** - Test handlers independently from LiveView
7. **Document custom events** - Document any custom event handlers for team clarity

## Related guides

- [Reusable Components](components.md) — embedding the index, form and show components in your own LiveView
- [Customizing & Extending Aurora UIX](../customization/customization.md) — the central customization hub; behavior hooks are [section 5](../customization/customization.md#5-customizing-liveview-behavior)
- [Custom Actions](../customization/custom_actions.md) — the buttons and links that fire the events you handle here
- [Layout System](layouts.md) — where handler modules are attached via layout options
- [Getting Started](../introduction/getting_started.md) — the required JavaScript hooks setup

