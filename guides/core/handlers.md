# Handlers and Events

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
