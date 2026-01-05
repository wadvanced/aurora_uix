# LiveView Integration

Aurora UIX leverages Phoenix LiveView to provide dynamic, real-time CRUD interfaces. The framework generates fully-functional LiveView modules at compile time, handling all the boilerplate while remaining customizable.

## How It Works

### Module Generation with `auix_create_ui`

The `auix_create_ui/0` macro generates a complete set of LiveView modules for your resource. For a resource named `product`, it creates:

```
Overview.Product                # Parent module (generated)
├── Overview.Product.Index      # Handles list/index, create, update, delete operations
└── Overview.Product.Show       # Handles detail view and show-specific operations
```

#### Generated Module Structure

Each generated module inherits from a handler implementation that provides:
- **Lifecycle callbacks** - `mount/3`, `handle_params/3`
- **Event handling** - `handle_event/3` for form submissions and CRUD operations
- **Async support** - `handle_info/2`, `handle_async/3` for background operations

**Index Module** (`Overview.Product.Index`):
- Lists entities with streaming for performance
- Handles create operations (new form submission)
- Handles update operations (inline or form edits)
- Handles delete operations with confirmation
- Manages filtering, sorting, and pagination
- Provides navigation between list and detail views

**Show Module** (`Overview.Product.Show`):
- Displays entity details
- Handles show-specific edits (if enabled in layout)
- Manages section/tab switching
- Provides navigation (back, forward through routes)

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
live "/:id", Overview.Product.Show, :show
live "/:id/show/edit", Overview.Product.Show, :edit
```

You can also selectively generate routes:

```elixir
# Read-only interface (no create/update)
auix_live_resources("/", Overview.Product, only: [:index, :show])

# Hide delete capability
auix_live_resources("/", Overview.Product, except: [:delete])
```

## Customizing Behavior

### Handler Hooks

Aurora UIX uses a handler delegation pattern. The generated LiveView modules delegate to handler modules (called "handler hooks") that implement the actual logic. You can customize specific behaviors by providing your own handler modules.

Handler hooks are specified directly in the layout DSL as options:
- **`handler_module`** - For index columns (handles list operations)
- **`edit_handler_module`** - For edit layout (handles form/edit operations)
- **`show_handler_module`** - For show layout (handles detail view operations)

#### Index Handler Hook

```elixir
defmodule MyApp.ProductIndexHandler do
  use Aurora.Uix.Templates.Basic.Handlers.IndexImpl

  alias Aurora.Uix.Templates.Basic.Handlers.IndexImpl
  alias Phoenix.LiveView.Socket

  # Override mount to customize data loading
  @impl Phoenix.LiveView
  def mount(params, session, %{assigns: %{auix: auix}} = socket) do
    # Apply custom query options (e.g., filtering)
    new_socket =
      auix.layout_tree
      |> Map.get(:opts, [])
      |> Keyword.put(:where, {:status, :eq, "active"})
      |> then(&Map.put(auix.layout_tree, :opts, &1))
      |> then(&assign_auix(socket, :layout_tree, &1))

    super(params, session, new_socket)
  end

  # Override apply_action for custom behavior on route changes
  @impl IndexImpl
  def apply_action(socket, params) do
    super(socket, params)
  end
end
```

#### Form/Edit Handler Hook

```elixir
defmodule MyApp.ProductEditHandler do
  use Aurora.Uix.Templates.Basic.Handlers.FormImpl

  alias Aurora.Uix.Templates.Basic.Handlers.FormImpl
  alias Phoenix.LiveView.Socket

  # Override save_entity to customize save logic
  @impl FormImpl
  def save_entity(%{assigns: %{action: :edit, auix: auix}}, _entity_params) do
    # Example: Skip saving on edit, just return the existing entity
    {:ok, auix.entity}
  end

  def save_entity(socket, entity_params) do
    # Use default implementation for create
    super(socket, entity_params)
  end
end
```

#### Show Handler Hook

```elixir
defmodule MyApp.ProductShowHandler do
  use Aurora.Uix.Templates.Basic.Handlers.ShowComponentImpl

  import Phoenix.LiveView, only: [push_patch: 2, put_flash: 3]
  alias Phoenix.LiveView.Socket

  # Override handle_event for custom event handling
  @impl Phoenix.LiveView
  def handle_event("delete", _params, socket) do
    # Custom delete logic
    {:noreply,
     socket
     |> put_flash(:info, "Product archived instead of deleted")
     |> push_patch(to: socket.assigns.auix[:_current_path])}
  end

  def handle_event(event, params, socket) do
    super(event, params, socket)
  end
end
```

#### Specifying Handler Hooks in Layout DSL

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
    # Index handler for custom filtering
    index_columns :product, [:name, :price],
      handler_module: MyApp.ProductIndexHandler

    # Edit handler for custom save logic
    edit_layout :product, edit_handler_module: MyApp.ProductEditHandler do
      inline [:name, :price, :description]
    end

    # Show handler for custom event handling
    show_layout :product, show_handler_module: MyApp.ProductShowHandler do
      inline [:name, :price, :description]
    end
  end
end
```

### Event Handling

Aurora UIX generates handlers for standard CRUD events. You can extend or override them:

#### Built-in Events

**Index View:**
- `"auix_mount"` - Initial mount and data loading
- `"auix_apply_action"` - Apply route action (new, edit, show)
- `"validate"` - Form validation
- `"save"` - Save entity (create/update)
- `"delete"` - Delete entity
- `"filters-changed"` - Apply filters
- `"filters-clear"` - Clear all filters
- `"sort-changed"` - Change sort column/direction
- `"page-changed"` - Navigate to page

**Show View:**
- `"auix_mount"` - Load entity details
- `"switch_section"` - Switch between tabs/sections
- `"delete"` - Delete entity
- `"auix_route_forward"` - Navigate forward
- `"auix_route_back"` - Navigate back

#### Adding Custom Events

```elixir
defmodule MyApp.ProductHandlers.Index do
  use Aurora.Uix.Templates.Basic.Handlers.Index

  @impl true
  def handle_event("publish", %{"id" => id}, socket) do
    product = Inventory.get_product(id)
    Inventory.publish_product(product)
    
    {:noreply, socket}
  end
end
```

## Key Callbacks

### mount/3
Initializes the LiveView socket with:
- `:auix` assigns containing context, schema, and configuration
- Stream setup for efficient list rendering
- Initial entity loading for show views

### handle_params/3
Called when URL parameters change. Handles:
- Route action determination (`:new`, `:edit`, `:show`)
- Form component assignment
- Routing stack management for navigation

### handle_event/3
Processes user events. Aurora UIX provides default implementations for:
- Form submission and validation
- CRUD operations
- Navigation
- Filtering and sorting

### handle_info/2
Handles asynchronous operations and notifications from other processes.

### handle_async/3
Manages async task results for long-running operations.

## Form Handling

Aurora UIX automatically generates forms based on your resource metadata. Forms are handled through the `"validate"` and `"save"` events:

```elixir
defmodule MyApp.ProductHandlers.Index do
  use Aurora.Uix.Templates.Basic.Handlers.Index

  @impl true
  def handle_event("save", %{"product" => product_params}, socket) do
    case Inventory.create_product(product_params) do
      {:ok, product} ->
        {:noreply,
         socket
         |> put_flash(:info, "Product created successfully")
         |> push_navigate(to: ~p"/products/#{product.id}")}
      
      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
```

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
def handle_event("refresh", _params, %{assigns: %{streams: streams}} = socket) do
  # Access all streams for the current view
  {:noreply, refresh_data(socket, streams)}
end

def handle_event("custom_action", _params, %{assigns: %{auix: auix}} = socket) do
  # Use the source_key to work with the primary stream
  source_key = auix.source_key  # :products
  {:noreply, stream_insert(socket, source_key, new_product)}
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
- Users can click sortable column headers to change sort order (if implemented)
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
  IO.inspect(socket.assigns.auix, label: "Aurora UIX Config")
  {:ok, socket}
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

