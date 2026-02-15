# LiveView Integration

Aurora UIX leverages Phoenix LiveView to provide dynamic, real-time CRUD interfaces. The framework generates fully-functional LiveView and LiveComponent modules at compile time, handling all the boilerplate while remaining customizable.

## How It Works

### Module Generation with `auix_create_ui`

The `auix_create_ui/0` macro generates a complete set of modules for your resource. For a resource named `product`, it creates:

```
Overview.Product                      # Parent module (generated)
├── Overview.Product.Index            # LiveView - Handles list/index page
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

### Using Generated Modules with Routes

The `auix_live_resources/3` macro creates all necessary routes:

```elixir
import Aurora.Uix.RouteHelper

scope "/products" do
  pipe_through(:browser)
  auix_live_resources("/", Overview.Product)
end

# Expands to:
live "/", Overview.Product.Index, :index
live "/new", Overview.Product.Index, :new
live "/:id/edit", Overview.Product.Index, :edit
live "/:id/show", Overview.Product.Index, :show
live "/:id/show-edit", Overview.Product.Index, :show_edit
```

All routes point to the Index LiveView, which dynamically renders FormComponent or ShowComponent in modals based on the `:live_action` assign.

You can also selectively generate routes:

```elixir
# Read-only interface (no create/update)
auix_live_resources("/", Overview.Product, only: [:index, :show])

# Hide delete capability
auix_live_resources("/", Overview.Product, except: [:delete])
```

## Customizing Behavior

### Handler Hooks

Aurora UIX uses a handler delegation pattern. The generated modules delegate to handler implementation modules that provide the actual logic. You can customize specific behaviors by providing your own handler modules.

Handler hooks are specified directly in the layout DSL as options:
- **`handler_module`** - For index columns (Index LiveView handler)
- **`edit_handler_module`** - For edit layout (FormComponent handler)
- **`show_handler_module`** - For show layout (ShowComponent handler)

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
| `apply_action/2` | IndexImpl | Apply route actions |

**Example - Override `auix_mount/3`:**

```elixir
defmodule MyApp.ProductIndexHandler do
  use Aurora.Uix.Templates.Basic.Handlers.IndexImpl

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
    
    {:noreply, 
     socket
     |> put_flash(:info, "Products published")
     |> refresh_current_page()}
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

  @impl IndexImpl
  def auix_handle_async(:custom_export, {:ok, result}, socket) do
    {:noreply, assign(socket, :export_result, result)}
  end

  def auix_handle_async(task, result, socket) do
    super(task, result, socket)
  end
end
```

**Example - Override `apply_action/2`:**

```elixir
defmodule MyApp.ProductIndexHandler do
  use Aurora.Uix.Templates.Basic.Handlers.IndexImpl

  @impl IndexImpl
  def apply_action(socket, params) do
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
| `save_entity/2` | FormImpl | Create or update entity |

**Example - Override `auix_update/2`:**

```elixir
defmodule MyApp.ProductFormHandler do
  use Aurora.Uix.Templates.Basic.Handlers.FormImpl

  @impl FormImpl
  def auix_update(assigns, socket) do
    socket
    |> assign(:form_metadata, load_metadata())
    |> assign(:templates, load_templates())
    |> then(&super(assigns, &1))
  end
end
```

**Example - Override `save_entity/2`:**

```elixir
defmodule MyApp.ProductFormHandler do
  use Aurora.Uix.Templates.Basic.Handlers.FormImpl

  # Customize creation logic
  @impl FormImpl
  def save_entity(%{assigns: %{action: :new, auix: auix}} = socket, entity_params) do
    # Add custom pre-processing
    entity_params = 
      entity_params
      |> Map.put("created_by", socket.assigns.current_user.id)
      |> enrich_params(socket)
    
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
  def save_entity(%{assigns: %{action: action, auix: auix}} = socket, entity_params)
      when action in [:edit, :show_edit] do
    # Custom validation before update
    if authorized?(socket, auix.entity) do
      case auix.modules.context.update_product(auix.entity, entity_params) do
        {:ok, product} ->
          audit_change(product, socket.assigns.current_user)
          {:ok, product}
        error -> error
      end
    else
      {:error, :unauthorized}
    end
  end

  defp enrich_params(params, socket), do: # ... custom logic
  defp authorized?(socket, entity), do: # ... authorization logic
  defp notify_team(product), do: # ... notification logic
  defp audit_change(product, user), do: # ... audit logic
end
```

**Example - Override `auix_handle_event/3`:**

```elixir
defmodule MyApp.ProductFormHandler do
  use Aurora.Uix.Templates.Basic.Handlers.FormImpl

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

  # Default to standard implementation for switch_section, auix_route_back, etc.
  def auix_handle_event(event, params, socket) do
    super(event, params, socket)
  end

  defp duplicate_product(product), do: # ... duplication logic
  defp archive_product(product), do: # ... archive logic
end
```

### Specifying Handler Hooks in Layout DSL

```elixir
defmodule MyAppWeb.ProductViews do
  use Aurora.Uix

  alias MyApp.Inventory

  auix_resource_metadata :product, context: Inventory, schema: Product do
    field :name, required: true
    field :description
    field :price
  end

  auix_create_ui do
    # Index handler for custom list behavior
    index_columns :product, [:name, :price],
      handler_module: MyApp.ProductIndexHandler

    # Edit handler for custom save logic
    edit_layout :product, edit_handler_module: MyApp.ProductFormHandler do
      inline [:name, :price, :description]
    end

    # Show handler for custom event handling
    show_layout :product, show_handler_module: MyApp.ProductShowHandler do
      inline [:name, :price, :description]
    end
  end
end
```

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
- `"index-layout-change"` - Handle filter form changes
- `"page-changed"` - Navigate to different page
- `"select-toggle-all"` - Toggle all item selection
- `"select-item"` - Toggle individual item selection

**FormComponent (LiveComponent):**
- `"validate"` - Form validation on field change
- `"save"` - Save entity (create/update)
- `"switch_section"` - Switch between tabs/sections in forms

**ShowComponent (LiveComponent):**
- `"switch_section"` - Switch between tabs/sections in show view
- `"auix_route_forward"` - Navigate forward
- `"auix_route_back"` - Navigate back

#### Adding Custom Events

Custom events are handled through the `auix_handle_event/3` callback in each handler.

**In Index Handler:**

```elixir
defmodule MyApp.ProductIndexHandler do
  use Aurora.Uix.Templates.Basic.Handlers.IndexImpl

  @impl IndexImpl
  def auix_handle_event("publish", %{"id" => id}, socket) do
    product = socket.assigns.auix.modules.context.get_product(id)
    {:ok, _} = socket.assigns.auix.modules.context.publish_product(product)
    
    {:noreply, 
     socket
     |> put_flash(:info, "Product published")
     |> refresh_current_page()}
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

  # Let ShowComponentImpl handle standard events (switch_section, auix_route_back)
  def auix_handle_event(event, params, socket) do
    super(event, params, socket)
  end
end
```

## Callback Reference

### Index LiveView Callbacks

The Index module is a full Phoenix LiveView with Aurora UIX callbacks for customization.

#### Aurora UIX Callbacks (IndexImpl)

| Callback | Purpose | When to Override |
|----------|---------|------------------|
| `auix_mount/3` | Initialize socket | Add custom initialization, load session data |
| `auix_handle_params/3` | Handle URL changes | Custom routing logic, filter extraction |
| `auix_handle_event/3` | Handle events | Add custom event handlers |
| `auix_handle_info/2` | Handle messages | Process custom info messages |
| `auix_handle_async/3` | Handle async results | Process custom async task results |
| `apply_action/2` | Apply route actions | Load action-specific data |

#### Phoenix.LiveView Callbacks (Advanced)

All standard Phoenix.LiveView callbacks are overridable for advanced use cases:
- `mount/3` - Raw socket initialization
- `handle_params/3` - Raw parameter handling
- `handle_event/3` - Raw event handling
- `handle_info/2` - Raw info message handling
- `handle_async/3` - Raw async result handling

### FormComponent Callbacks

The FormComponent is a Phoenix.LiveComponent with Aurora UIX callbacks for customization.

#### Aurora UIX Callbacks (FormImpl)

| Callback | Purpose | When to Override |
|----------|---------|------------------|
| `auix_update/2` | Initialize/update component | Add metadata, load templates |
| `auix_handle_event/3` | Handle custom events | Add custom form interactions |
| `save_entity/2` | Save/update entity | Custom validation, authorization, side effects |

#### Phoenix.LiveComponent Callbacks (Advanced)

- `update/2` - Raw component update
- `handle_event/3` - Raw event handling (note: "save" is handled specially)

### ShowComponent Callbacks

The ShowComponent is a Phoenix.LiveComponent with Aurora UIX callbacks for customization.

#### Aurora UIX Callbacks (ShowComponentImpl)

| Callback | Purpose | When to Override |
|----------|---------|------------------|
| `auix_update/2` | Initialize/update component | Load analytics, related data |
| `auix_handle_event/3` | Handle custom events | Add custom show view actions |

#### Phoenix.LiveComponent Callbacks (Advanced)

- `update/2` - Raw component update
- `handle_event/3` - Raw event handling

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

See the **FormComponent Callbacks** section above for details on overriding `auix_update/2`, `auix_handle_event/3`, and `save_entity/2`.

## Working with Streams

Aurora UIX uses Phoenix LiveView streams for efficient list rendering. Streams are automatically managed for the index view and automatically created with specific naming conventions.

### Stream Naming

Aurora UIX creates multiple streams for different layout types:

- **Primary stream** - Named after the resource key (e.g., `:products` for a product index)
- **Alternate streams** - For different view types, named as `#{source_key}__#{suffix}`:
  - `:products__index` - For table/list index view
  - `:products__card` - For card-based index view
  - `:products__calendar` - For calendar index view (if configured)
  - Additional streams based on your layout configuration

The framework automatically manages these streams, inserting, updating, or deleting entries as needed.

### Accessing Streams in Handler Hooks

To access streams in a custom handler:

```elixir
defmodule MyApp.ProductIndexHandler do
  use Aurora.Uix.Templates.Basic.Handlers.IndexImpl

  @impl IndexImpl
  def auix_handle_event("refresh", _params, %{assigns: %{streams: streams}} = socket) do
    # Access all streams for the current view
    {:noreply, refresh_data(socket, streams)}
  end

  @impl IndexImpl
  def auix_handle_event("custom_action", _params, %{assigns: %{auix: auix}} = socket) do
    # Use the source_key to work with the primary stream
    source_key = auix.source_key  # :products
    {:noreply, stream_insert(socket, source_key, new_product)}
  end

  def auix_handle_event(event, params, socket) do
    super(event, params, socket)
  end
end
```

### Stream Operations

Standard Phoenix LiveView stream operations work with Aurora UIX streams:

```elixir
# Insert a new entry
stream_insert(socket, :products, new_product)

# Update an existing entry
stream_insert(socket, :products, updated_product)

# Delete an entry
stream_delete(socket, :products, deleted_product)

# Reset the entire stream
stream(socket, :products, fetched_products)
```

## Filtering and Sorting

Aurora UIX supports sorting via configuration in both resource metadata and layout DSL. Sorting is applied automatically and can be customized per view.

### Configuring Default Sort Order

**Option 1: In Resource Metadata**

Define a default sort order at the resource level:

```elixir
auix_resource_metadata :product, context: Inventory, schema: Product,
  order_by: :reference  # Sort by reference field by default
do
  field :name
  field :reference
  field :price
end
```

**Option 2: In Layout DSL**

Override or specify sort order for a specific view:

```elixir
auix_create_ui do
  # Override metadata sort with name-based sort
  index_columns :product, [:id, :reference, :name, :cost],
    order_by: :name
end
```

### How Sorting Works

The `order_by` option:
- Can be a single field atom (`:name`)
- Determines the default sort column when the index loads
- Is applied through the query layer to the database
- Can be dynamically changed by the user via column headers (if enabled)

### Example: Default Sort Configuration

```elixir
# Metadata defines reference as default sort
auix_resource_metadata :product, context: Inventory, schema: Product,
  order_by: :reference

auix_create_ui do
  # Layout overrides with name sort
  index_columns :product, [:id, :reference, :name, :cost],
    order_by: :name
  
  # Show layout has no sort (N/A for detail view)
  show_layout :product do
    inline [:name, :reference, :price]
  end
end
```

When the index loads:
- Products are sorted by `:name` (from layout)
- The sort is applied at the database level for performance

## Navigation

Aurora UIX handles navigation through:

1. **LiveView patches** - For route changes within the same view (fast)
2. **LiveView pushes** - For full page navigation
3. **Routing stack** - Maintains history for back/forward navigation

Navigate between views:

```elixir
push_navigate(socket, to: ~p"/products/#{product.id}")
push_patch(socket, to: ~p"/products/#{product.id}/edit")
```

## Performance Considerations

### Streams for Large Lists

Aurora UIX uses Phoenix LiveView streams for index views, which efficiently handle:
- Inserts/updates/deletes without full re-render
- Pagination for large datasets
- Lazy loading capabilities

### Preloading Associations

Configure preloads in your resource metadata to minimize N+1 queries:

```elixir
auix_resource_metadata :product, context: Inventory, schema: Product do
  field :name
  field :category, preload: true  # Preload associated data
end
```

### Async Operations

Use `handle_async/3` for heavy operations:

```elixir
def handle_event("export", _params, socket) do
  {:noreply,
   start_async(socket, :export, fn -> export_products() end)}
end

def handle_async(:export, {:ok, file_path}, socket) do
  {:noreply, push_download(socket, :file, file_path)}
end
```

## Debugging

### Inspecting Socket Assigns

The `:auix` assign contains all configuration and runtime state:

```elixir
def mount(_params, _session, socket) do
  # Set assigns and do my own logic
  {:ok, assign(socket, :something, :anything}
end
```

### LiveView DevTools

Use Phoenix LiveDashboard to monitor:
- Active LiveView processes
- Socket state and assigns
- Event flow and timing

Enable in development:

```elixir
# config/dev.exs
config :aurora_uix, :dev_routes, true
```

Visit `http://localhost:4000/dev/dashboard`

## Best Practices

1. **Keep handlers focused** - One concern per handler module
2. **Use streams** - Always use streams for list views instead of assigning the full list
3. **Validate early** - Validate inputs in `handle_event` before database operations
4. **Handle errors gracefully** - Provide user feedback for all operations
5. **Preload data** - Configure preloads to avoid N+1 queries
6. **Test in isolation** - Test handlers independently from LiveView
7. **Document custom events** - Document any custom event handlers for team clarity

