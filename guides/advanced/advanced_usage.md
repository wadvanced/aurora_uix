# Advanced Usage

This guide covers advanced topics for customizing and extending Aurora UIX.

## How Templates Work

Templates are the core of Aurora UIX's code generation system. A template is a module that implements the `Aurora.Uix.Template` behaviour and is responsible for:

1. **Code Generation**: Converting layout configurations into LiveView modules
2. **Component Rendering**: Generating the HTML/component markup for different view types
3. **Event Handling**: Creating the logic for user interactions

### The Template Lifecycle

When you define a resource with `auix_resource_metadata`, Aurora UIX:

1. Parses your field configurations
2. Builds a layout tree from `@auix_layout_trees` (defines structure)
3. Calls the configured template's `generate_module/1` callback
4. The template generates LiveView modules for each layout type (index, show, form)

### Template Callbacks

A template module must implement:

- **`generate_module(parsed_opts)`**: Receives a map with:
  - `:layout_tree` - The layout structure (tag: :index, :show, :form, etc.)
  - `:fields` - Field configurations
  - `:modules` - Module references
  - `:name` - Resource name
  
  Returns generated Macro code for the LiveView module.

- **`default_core_components_module()`**: Returns the module containing your core UI components (forms, tables, buttons, modals, etc.)

- **`layout_tags()`**: Returns list of supported layout tags (e.g., `:index`, `:show`, `:form`)

- **`default_theme_name()`**: Returns the default theme atom

### Example: Creating a Custom Template

```elixir
defmodule MyApp.CustomTemplate do
  @behaviour Aurora.Uix.Template

  @impl true
  def generate_module(parsed_opts) do
    case parsed_opts.layout_tree.tag do
      :index -> generate_index_module(parsed_opts)
      :show -> generate_show_module(parsed_opts)
      :form -> generate_form_module(parsed_opts)
      _ -> quote do end
    end
  end

  @impl true
  def layout_tags do
    [:index, :show, :form]
  end

  @impl true
  def default_core_components_module do
    MyAppWeb.CoreComponents
  end

  @impl true
  def default_theme_name do
    :default
  end

  # Your custom generator logic...
  defp generate_index_module(parsed_opts) do
    quote do
      # Custom index module generation
    end
  end

  defp generate_show_module(parsed_opts) do
    quote do
      # Custom show module generation
    end
  end

  defp generate_form_module(parsed_opts) do
    quote do
      # Custom form module generation
    end
  end
end
```

Then configure it in `config.exs`:

```elixir
config :aurora_uix, :template, MyApp.CustomTemplate
```

## Creating Custom Layouts

You can create layouts that exclude certain views or add custom ones by modifying your `@auix_layout_trees`.

### Example: Custom Template Without Index/Show

```elixir
defmodule MyAppWeb.Product do
  use Aurora.UixWeb, :live_view
  alias Aurora.Uix.TreePath

  auix_resource_metadata(:product, context: Inventory, schema: Product) do
    field(:name, placeholder: "Product name")
    field(:price, placeholder: "0.00")
  end

  # Only define form layout - no index or show
  @auix_layout_trees %TreePath{
    tag: :form,
    name: :product,
    inner_elements: [
      %TreePath{tag: :field, name: :name},
      %TreePath{tag: :field, name: :price}
    ]
  }
end
```

The template will only generate a form module and skip index/show generation.

## Understanding Macro Type Conversions

Aurora UIX macros convert your declarative configurations into strongly-typed Elixir structures. Understanding this conversion is key to extending the system.

### Field Macro Conversion

When you write:

```elixir
field(:name, placeholder: "Enter name", required: true)
```

This converts to an `Aurora.Uix.Field` struct:

```elixir
%Aurora.Uix.Field{
  key: :name,
  type: :string,           # Auto-detected from schema
  name: "name",
  label: "Name",           # Auto-generated from field name
  placeholder: "Enter name",
  required: true,
  # ... other defaults
}
```

### Resource Macro Conversion

`auix_resource_metadata` converts to an `Aurora.Uix.Resource` struct containing:

- `:name` - Resource identifier
- `:schema` - Ecto schema module
- `:context` - Context module for data operations
- `:fields` - Map of field configurations
- `:order_by` - Query ordering preferences

### Layout Tree Conversion

`@auix_layout_trees` defines the UI structure as `Aurora.Uix.TreePath` structures:

```elixir
%Aurora.Uix.TreePath{
  tag: :form,              # View type: :form, :index, :show, :inline
  name: :product,          # Resource name
  inner_elements: [        # Nested elements
    %TreePath{tag: :field, name: :name},
    %TreePath{tag: :field, name: :price}
  ]
}
```

**Supported tags:**
- `:form` - Form view for creating/editing
- `:index` - List/table view
- `:show` - Detail view
- `:inline` - Horizontal field grouping
- `:field` - Individual field reference
- `:one_to_many` - Related records table
- `:embeds_many` - Embedded collection

### Learning More About Conversions

Check test files to see real-world examples of these conversions:

- `test/cases_live/manual_ui_test.exs` - Complete layout tree examples
- `test/cases_live/manual_resource_test.exs` - Resource metadata structures
- `test/cases_live/manual_layouts_test.exs` - Layout option configurations

## Separating Resource Metadata from UI Modules

Resource metadata can be defined **outside** the module that generates the UI. This separation enables powerful reusability patterns where metadata can be shared across multiple UI modules, views, and layouts.

### Why Separate Metadata?

Separating resource metadata from UI modules provides several benefits:

**1. Metadata Reusability**
- Define different metadata variants for the same schema
- Share metadata across multiple UI modules without duplication
- Create focused metadata sets for different use cases

**2. Avoiding Duplication**
- Field attributes (placeholders, validation rules, formatting) are defined once
- Field configurations don't need to be repeated across different UIs
- Changes to field behavior apply everywhere automatically

**3. One Schema, Many Representations**
Resource metadata is **not** a 1:1 relationship with schemas. One schema can have multiple metadata representations based on role/scope:
- **Product (Admin)** - All fields including stock, cost, inactive flag
- **Product (Customer)** - Only public fields like name, description, price
- **Product (Audit)** - Only audit fields like timestamps and who modified it
- **Product (Internal)** - Fields needed by internal teams

This allows you to define how each schema is represented once, then use those representations across different views based on who's viewing the data.

### Example Use Cases

You can create multiple metadata sets for the same schema:

```elixir
# Full product metadata - admin representation
auix_resource_metadata :product_admin, context: Inventory, schema: Product do
  field :id, hidden: true
  field :reference, required: true, max_length: 50
  field :name, required: true, max_length: 200
  field :description, html_type: :textarea
  field :quantity_at_hand, precision: 12, scale: 2
  field :quantity_initial, precision: 12, scale: 2
  field :list_price, precision: 12, scale: 2
  field :rrp, precision: 12, scale: 2
  field :inactive, disabled: false
  field :inserted_at, readonly: true
  field :updated_at, readonly: true
end

# Customer-facing product metadata
auix_resource_metadata :product_customer, context: Inventory, schema: Product do
  field :reference, required: true
  field :name, required: true
  field :description
  field :list_price
  field :rrp
end

# Audit/logging metadata
auix_resource_metadata :product_audit, context: Inventory, schema: Product do
  field :reference
  field :inserted_at, readonly: true
  field :updated_at, readonly: true
end
```

Then use them in different views (organized by role/context):

```elixir
# Admin portal uses admin metadata
defmodule MyAppWeb.Admin.ProductsLive do
  @auix_resource_metadata MyAppWeb.Metadata.Inventory.Product.auix_resource(:product_admin)
  
  auix_create_ui do
    index_columns(:product_admin, [:reference, :name, :quantity_at_hand, :list_price])
  end
end

# Customer portal uses customer metadata
defmodule MyAppWeb.Customer.ProductsLive do
  @auix_resource_metadata MyAppWeb.Metadata.Inventory.Product.auix_resource(:product_customer)
  
  auix_create_ui do
    index_columns(:product_customer, [:reference, :name, :list_price, :rrp])
  end
end

# Audit logs use audit metadata
defmodule MyAppWeb.Audit.ProductsLive do
  @auix_resource_metadata MyAppWeb.Metadata.Inventory.Product.auix_resource(:product_audit)
  
  auix_create_ui do
    index_columns(:product_audit, [:reference, :inserted_at, :updated_at])
  end
end
```

### Accessing Separated Metadata

To access metadata defined in another module, use the `auix_resource/1` function:

```elixir
@auix_resource_metadata MyApp.ResourceMetadata.auix_resource(:product)
```

This retrieves the compiled resource metadata struct from the metadata module.

### Introspecting generated UI modules

Every module produced by `auix_create_ui` exposes two introspection functions that are useful for debugging and for tooling that inspects the generated UI structure at runtime:

- **`auix_layout_trees/0`** — returns the layout trees as you defined them (excluding the defaults Aurora UIX injects automatically). Useful for verifying that custom layout macros were applied correctly.

  ```elixir
  MyAppWeb.Products.Index.auix_layout_trees()
  ```

- **`auix_configurations/0`** — returns the full configuration map from which all LiveView code is generated. This is the "fat" intermediate representation: fields, metadata, module references, and resolved options. Useful when debugging unexpected rendering or when building tooling on top of Aurora UIX.

  ```elixir
  MyAppWeb.Products.Index.auix_configurations()
  ```

### Recommended Project Structure

Organize your application with metadata modules in the web layer, grouped by the **schema context** they represent, while views are grouped by **role/app context**:

```
lib/my_app_web/
├── metadata/                    # Organized by SCHEMA CONTEXT
│   ├── inventory/               # (What domain data it represents)
│   │   ├── product.ex           # Product representations (admin, customer, audit)
│   │   └── order.ex             # Order representations (admin, customer, audit)
│   └── accounts/                # Another schema context
│       └── user.ex              # User representations
├── live/                        # Organized by ROLE/VIEW CONTEXT
│   ├── admin/                   # (Who uses it - admin users)
│   │   ├── products_live.ex
│   │   └── orders_live.ex
│   ├── customer/                # (Who uses it - customers)
│   │   ├── products_live.ex
│   │   └── orders_live.ex
│   └── public/                  # (Who uses it - public/guests)
│       └── product_catalog_live.ex
└── ...
```

**Key Insight:**
- **Metadata folder structure** mirrors **schema contexts** (inventory, accounts, etc.)
  - This shows *what data* the metadata represents
  - One schema can have many metadata variants (admin, customer, audit, etc.)
  
- **Live folder structure** mirrors **role/view contexts** (admin, customer, public, etc.)
  - This shows *who* uses each view
  - Each role-based view uses the appropriate metadata variant for that role

### Example Metadata Module

Create metadata modules in the web layer, organized by schema context:

```elixir
# lib/my_app_web/metadata/inventory/product.ex
defmodule MyAppWeb.Metadata.Inventory.Product do
  use Aurora.Uix.Layout.ResourceMetadata
  
  alias MyApp.Inventory
  alias MyApp.Inventory.Product

  # Admin representation - all fields including sensitive data
  auix_resource_metadata :product_admin, context: Inventory, schema: Product do
    field :id, hidden: true
    field :reference, required: true, max_length: 50
    field :name, required: true, max_length: 200
    field :description, html_type: :textarea
    field :quantity_at_hand
    field :quantity_initial
    field :list_price, precision: 12, scale: 2
    field :rrp, precision: 12, scale: 2
    field :inactive, disabled: false
    field :inserted_at, readonly: true
    field :updated_at, readonly: true
  end

  # Customer representation - only public fields
  auix_resource_metadata :product_customer, context: Inventory, schema: Product do
    field :reference, required: true
    field :name, required: true
    field :description
    field :list_price
    field :rrp
  end

  # Audit representation - only audit/tracking fields
  auix_resource_metadata :product_audit, context: Inventory, schema: Product do
    field :reference
    field :inserted_at, readonly: true
    field :updated_at, readonly: true
  end
end
```

Then use metadata in views organized by role:

```elixir
# lib/my_app_web/live/admin/products_live.ex
# Admin role sees full product information
defmodule MyAppWeb.Admin.ProductsLive do
  use MyAppWeb, :live_view
  
  alias MyAppWeb.Metadata.Inventory.Product, as: ProductMetadata
  
  @auix_resource_metadata ProductMetadata.auix_resource(:product_admin)
  
  auix_create_ui do
    index_columns(:product_admin, [
      :reference, :name, :quantity_at_hand, :list_price, :inactive
    ])
    
    edit_layout :product_admin do
      inline([:reference, :name])
      inline([:quantity_at_hand, :quantity_initial])
      inline([:list_price, :rrp])
      inline([:inserted_at, :updated_at, :inactive])
    end
  end
  
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
  
  # ... live view handlers ...
end

# lib/my_app_web/live/customer/products_live.ex
# Customer role sees only public product information
defmodule MyAppWeb.Customer.ProductsLive do
  use MyAppWeb, :live_view
  
  alias MyAppWeb.Metadata.Inventory.Product, as: ProductMetadata
  
  @auix_resource_metadata ProductMetadata.auix_resource(:product_customer)
  
  auix_create_ui do
    index_columns(:product_customer, [:reference, :name, :list_price, :rrp])
    
    show_layout :product_customer do
      inline([:reference, :name])
      inline([:description])
      inline([:list_price, :rrp])
    end
  end
  
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
  
  # ... live view handlers ...
end

# lib/my_app_web/live/public/product_catalog_live.ex
# Public catalog also uses customer metadata
defmodule MyAppWeb.Public.ProductCatalogLive do
  use MyAppWeb, :live_view
  
  alias MyAppWeb.Metadata.Inventory.Product, as: ProductMetadata
  
  @auix_resource_metadata ProductMetadata.auix_resource(:product_customer)
  
  auix_create_ui do
    index_columns(:product_customer, [:name, :list_price])
  end
  
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
  
  # ... live view handlers ...
end
```

### Single vs Multiple Resources

You can organize metadata for one or multiple schemas within a metadata context module:

**Single Schema with Multiple Representations:**
```elixir
# lib/my_app_web/metadata/inventory/product.ex
defmodule MyAppWeb.Metadata.Inventory.Product do
  use Aurora.Uix.Layout.ResourceMetadata
  
  alias MyApp.Inventory
  alias MyApp.Inventory.Product

  auix_resource_metadata :product_admin, context: Inventory, schema: Product do
    # ... admin representation ...
  end

  auix_resource_metadata :product_customer, context: Inventory, schema: Product do
    # ... customer representation ...
  end
end

# In your views:
alias MyAppWeb.Metadata.Inventory.Product, as: ProductMetadata

@auix_resource_metadata ProductMetadata.auix_resource(:product_admin)
@auix_resource_metadata ProductMetadata.auix_resource(:product_customer)
```

**Multiple Schemas in Same Context:**
```elixir
# lib/my_app_web/metadata/inventory/catalog.ex
# Group related schemas together
defmodule MyAppWeb.Metadata.Inventory.Catalog do
  use Aurora.Uix.Layout.ResourceMetadata
  
  alias MyApp.Inventory
  alias MyApp.Inventory.{Product, Category, Stock}

  # Product representations
  auix_resource_metadata :product_admin, context: Inventory, schema: Product do
    # ...
  end

  auix_resource_metadata :product_customer, context: Inventory, schema: Product do
    # ...
  end

  # Category representations
  auix_resource_metadata :category_admin, context: Inventory, schema: Category do
    # ...
  end

  # Stock representations
  auix_resource_metadata :stock_admin, context: Inventory, schema: Stock do
    # ...
  end
end

# In your views:
alias MyAppWeb.Metadata.Inventory.Catalog, as: CatalogMetadata

@auix_resource_metadata CatalogMetadata.auix_resource(:product_admin)
@auix_resource_metadata CatalogMetadata.auix_resource(:category_admin)
```

**Completely Separate Metadata Modules (Fine-Grained):**
```elixir
# lib/my_app_web/metadata/inventory/products.ex
defmodule MyAppWeb.Metadata.Inventory.Products do
  use Aurora.Uix.Layout.ResourceMetadata
  # Product representations only
end

# lib/my_app_web/metadata/inventory/categories.ex
defmodule MyAppWeb.Metadata.Inventory.Categories do
  use Aurora.Uix.Layout.ResourceMetadata
  # Category representations only
end

# In your views, use the specific modules:
alias MyAppWeb.Metadata.Inventory.Products, as: ProductMetadata
alias MyAppWeb.Metadata.Inventory.Categories, as: CategoryMetadata

@auix_resource_metadata ProductMetadata.auix_resource(:product_admin)
@auix_resource_metadata CategoryMetadata.auix_resource(:category_admin)
```

**Choose based on your preferences:**
- **Single module** - Good for small contexts with few schemas
- **Grouped module** - Good for related schemas (e.g., inventory catalog items)
- **Separate modules** - Good for large contexts or when schemas have complex, independent metadata

See test files for complete examples:
- `test/cases_live/separated_single_resource_ui_test.exs` - Single resource separation
- `test/cases_live/separated_multiple_resources_ui_test.exs` - Multiple resources separation

## Defining Custom Backends

Aurora UIX's architecture is extensible and supports custom backend implementations beyond the built-in Context (Ecto) and Ash Framework integrations. You can integrate other data layers, ORMs, or custom data sources by implementing the required behaviours.

### Backend Architecture Overview

Aurora UIX uses a polymorphic dispatch system for CRUD operations through three main components:

1. **Connector** (`Aurora.Uix.Integration.Connector`) - Wraps backend-specific configuration with a type identifier
2. **CRUD Interface** (`Aurora.Uix.Integration.Crud`) - Behaviour defining unified CRUD operations
3. **Parser Interface** (`Aurora.Uix.Parser`) - Behaviour for extracting metadata from resources

### When to Create a Custom Backend

Consider creating a custom backend when:

- Using a different ORM or database library (e.g., Mnesia, Datomic adapters)
- Integrating with external APIs (REST, GraphQL, gRPC)
- Working with non-relational data sources (Redis, document stores)
- Implementing custom business logic layers
- Needing specialized query or caching strategies

### Step 1: Implement the CRUD Behaviour

Create a module implementing `Aurora.Uix.Integration.Crud` with all 8 required callbacks:

```elixir
defmodule MyApp.CustomBackend.Crud do
  @moduledoc """
  Custom backend CRUD implementation for MyApp data layer.
  """
  
  @behaviour Aurora.Uix.Integration.Crud

  alias Aurora.Ctx.Pagination
  alias MyApp.CustomBackend.CrudSpec

  @impl true
  def list(crud_spec, opts) do
    # Implement listing logic for your backend
    # Return: %Pagination{entries: [...], page: 1, pages_count: N}
    resource = crud_spec.resource_module
    entries = resource.all(opts)
    
    %Pagination{
      entries: entries,
      page: Keyword.get(opts, :page, 1),
      pages_count: 1,
      total_count: length(entries)
    }
  end

  @impl true
  def to_page(crud_spec, pagination, page) do
    # Implement pagination navigation
    %{pagination | page: page}
  end

  @impl true
  def get(crud_spec, id, opts) do
    # Implement single resource retrieval
    crud_spec.resource_module.find(id, opts)
  end

  @impl true
  def change(crud_spec, entity, form_name, attrs) do
    # Create a changeset or form for the entity
    # Return: changeset structure compatible with Phoenix forms
    crud_spec.resource_module.changeset(entity, attrs)
  end

  @impl true
  def new(crud_spec, attrs, opts) do
    # Create a new resource struct
    struct(crud_spec.resource_module, attrs)
  end

  @impl true
  def create(crud_spec, params) do
    # Implement resource creation
    crud_spec.resource_module.insert(params)
  end

  @impl true
  def update(crud_spec, entity, params) do
    # Implement resource update
    crud_spec.resource_module.update(entity, params)
  end

  @impl true
  def delete(crud_spec, entity) do
    # Implement resource deletion
    crud_spec.resource_module.delete(entity)
  end
end
```

### Step 2: Define a CrudSpec Structure

Create a module to hold backend-specific configuration:

```elixir
defmodule MyApp.CustomBackend.CrudSpec do
  @moduledoc """
  Specification structure for custom backend operations.
  """
  
  @type t() :: %__MODULE__{
    resource_module: module(),
    action: atom(),
    options: keyword()
  }

  @enforce_keys [:resource_module, :action]
  defstruct [:resource_module, :action, options: []]

  @doc """
  Creates a new CrudSpec for the custom backend.
  """
  def new(resource_module, action, options \\ []) do
    %__MODULE__{
      resource_module: resource_module,
      action: action,
      options: options
    }
  end
end
```

### Step 3: Implement Context Parser

Create a parser to discover and configure CRUD functions from your backend:

```elixir
defmodule MyApp.CustomBackend.ContextParserDefaults do
  @moduledoc """
  Parser for resolving custom backend actions and configurations.
  """
  
  alias Aurora.Uix.Integration.Connector
  alias MyApp.CustomBackend.CrudSpec

  @doc """
  Resolves default values for backend operations.
  
  Called by Aurora.Uix.Parser to discover CRUD actions.
  """
  def option_value(_parsed_opts, resource_config, opts, :list_function) do
    crud_spec = CrudSpec.new(
      resource_config.schema,
      :list,
      Keyword.get(opts, :list_options, [])
    )
    
    Connector.new(crud_spec, :custom)
  end

  def option_value(_parsed_opts, resource_config, opts, :get_function) do
    crud_spec = CrudSpec.new(
      resource_config.schema,
      :get,
      Keyword.get(opts, :get_options, [])
    )
    
    Connector.new(crud_spec, :custom)
  end

  def option_value(_parsed_opts, resource_config, opts, :create_function) do
    crud_spec = CrudSpec.new(
      resource_config.schema,
      :create,
      Keyword.get(opts, :create_options, [])
    )
    
    Connector.new(crud_spec, :custom)
  end

  def option_value(_parsed_opts, resource_config, opts, :update_function) do
    crud_spec = CrudSpec.new(
      resource_config.schema,
      :update,
      Keyword.get(opts, :update_options, [])
    )
    
    Connector.new(crud_spec, :custom)
  end

  def option_value(_parsed_opts, resource_config, opts, :delete_function) do
    crud_spec = CrudSpec.new(
      resource_config.schema,
      :delete,
      Keyword.get(opts, :delete_options, [])
    )
    
    Connector.new(crud_spec, :custom)
  end

  def option_value(_parsed_opts, resource_config, opts, :change_function) do
    crud_spec = CrudSpec.new(
      resource_config.schema,
      :change,
      Keyword.get(opts, :change_options, [])
    )
    
    Connector.new(crud_spec, :custom)
  end

  def option_value(_parsed_opts, resource_config, opts, :new_function) do
    new_fn = Keyword.get(opts, :new_function, &default_new_function/2)
    
    crud_spec = CrudSpec.new(
      resource_config.schema,
      :new,
      [new_function: new_fn]
    )
    
    Connector.new(crud_spec, :custom)
  end

  # Fallback for unhandled options
  def option_value(_parsed_opts, _resource_config, _opts, _key), do: nil

  defp default_new_function(attrs, _opts) do
    # Default implementation for creating new structs
    %{}
  end
end
```

### Step 4: Implement Fields Parser

Create a parser for extracting field metadata from your resources:

```elixir
defmodule MyApp.CustomBackend.FieldsParser do
  @moduledoc """
  Parses fields from custom backend resources.
  """
  
  alias Aurora.Uix.Field

  @doc """
  Parses all fields from a custom resource.
  """
  def parse_fields(resource_module, resource_name) do
    # Extract field definitions from your resource
    resource_module.__fields__()
    |> Enum.map(&parse_field(resource_module, resource_name, &1))
  end

  defp parse_field(resource_module, resource_name, field_spec) do
    Field.new(
      key: field_spec.name,
      type: field_spec.type,
      html_type: infer_html_type(field_spec.type),
      label: humanize(field_spec.name),
      resource: resource_name,
      required: field_spec.required || false,
      length: field_spec.max_length || 255
    )
  end

  defp infer_html_type(:string), do: :text
  defp infer_html_type(:integer), do: :number
  defp infer_html_type(:boolean), do: :checkbox
  defp infer_html_type(:date), do: :date
  defp infer_html_type(:datetime), do: :"datetime-local"
  defp infer_html_type(_), do: :text

  defp humanize(atom) when is_atom(atom) do
    atom
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end
end
```

### Step 5: Register Your Backend

Add your backend to the application configuration:

```elixir
# config/config.exs

config :aurora_uix, :crud_integration_modules,
  ash: Aurora.Uix.Integration.Ash.Crud,
  ctx: Aurora.Uix.Integration.Ctx.Crud,
  custom: MyApp.CustomBackend.Crud  # Your custom backend
```

### Step 6: Use Your Custom Backend

Define resources using your custom backend:

```elixir
defmodule MyAppWeb.ProductViews do
  use Aurora.Uix

  alias MyApp.Products.Product

  # Use custom backend options
  auix_resource_metadata :product, 
    schema: Product,
    type: :custom,  # Specify your backend type
    custom_option: :value do
    
    field :name, required: true
    field :price, html_type: :number
  end

  auix_create_ui do
    index_columns(:product, [:name, :price])
    
    show_layout :product do
      stacked([:name, :price])
    end
    
    edit_layout :product do
      inline([:name, :price])
    end
  end
end
```

### Step 7: Detect Backend Type (Optional)

If you want automatic backend type detection, extend the resource metadata macro detection logic:

```elixir
# In your custom macro or configuration
defp detect_backend_type(opts) do
  cond do
    Keyword.has_key?(opts, :custom_resource) -> :custom
    Keyword.has_key?(opts, :ash_resource) -> :ash
    Keyword.has_key?(opts, :context) -> :ctx
    true -> :ctx  # default
  end
end
```

### Key Considerations

**CRUD Spec Design:**
- Keep backend-specific configuration in your CrudSpec struct
- Store resource references, action names, and options
- Make it serializable if storing in assigns

**Field Parsing:**
- Map your backend's types to Ecto-compatible types
- Handle associations and embedded resources appropriately
- Use the `__` naming convention for nested resources

**Error Handling:**
- Wrap backend errors in standard `{:ok, result}` or `{:error, reason}` tuples
- Provide meaningful error messages
- Handle missing resources gracefully

**Pagination:**
- Return `Aurora.Ctx.Pagination` structs from list operations
- Implement proper page navigation in `to_page/3`
- Track total counts when possible

**Testing:**
- Create integration tests for your CRUD operations
- Test field parsing with various resource configurations
- Verify connector type resolution

### Example: GraphQL Backend

Here's a minimal example for a GraphQL backend:

```elixir
defmodule MyApp.GraphQLBackend.Crud do
  @behaviour Aurora.Uix.Integration.Crud
  
  alias Aurora.Ctx.Pagination
  alias MyApp.GraphQLBackend.Client

  @impl true
  def list(crud_spec, opts) do
    query = """
    query List#{crud_spec.resource_name} {
      #{crud_spec.resource_name}(limit: #{opts[:limit] || 20}) {
        id
        #{Enum.join(crud_spec.fields, "\n")}
      }
    }
    """
    
    case Client.query(query) do
      {:ok, %{data: data}} ->
        %Pagination{
          entries: data[crud_spec.resource_name],
          page: 1,
          pages_count: 1
        }
      
      {:error, reason} ->
        %Pagination{entries: [], page: 1, pages_count: 0, error: reason}
    end
  end

  @impl true
  def get(crud_spec, id, _opts) do
    query = """
    query Get#{crud_spec.resource_name} {
      #{crud_spec.resource_name}(id: "#{id}") {
        id
        #{Enum.join(crud_spec.fields, "\n")}
      }
    }
    """
    
    case Client.query(query) do
      {:ok, %{data: data}} -> data[crud_spec.resource_name]
      {:error, _reason} -> nil
    end
  end

  # Implement other callbacks...
end
```

### References

For implementation examples, see:
- `lib/aurora_uix/integration/ctx/` - Context backend implementation
- `lib/aurora_uix/integration/ash/` - Ash Framework backend implementation
- `lib/aurora_uix/integration/connector.ex` - Connector structure
- `lib/aurora_uix/integration/crud.ex` - CRUD behaviour definition

## Managing Actions

The content of this section has moved to its own guide:
[Custom Actions](../customization/custom_actions.md) — action groups by layout type,
the add/insert/replace/remove operations, action handlers, and processing order.

## Creating Custom Registered Themes

The content of this section has moved to its own guide:
[Creating Custom Registered Themes](../customization/theming.md) — the three-layer theme
architecture, `use Aurora.Uix.Templates.Theme`, light/dark modes, and theme registration.

## Notes

- Only the callbacks listed in the Template behaviour are required and present in the default template implementation.
- The built-in `Aurora.Uix.Templates.Basic` is designed for extensibility - you can create wrappers or custom templates by referencing its structure.
- If you need custom markup or layout parsing, add additional functions to your template modules.
- The rendering pipeline is separated into handlers (event processing) and renderers (HTML generation) for flexible customization.

## Related guides

- [Customizing & Extending Aurora UIX](../customization/customization.md) — the central customization hub
- [Custom Actions](../customization/custom_actions.md) — the action system reference
- [Creating Custom Registered Themes](../customization/theming.md) — theme authoring
- [Overriding Components](../customization/overriding_components.md) — runtime component replacement
- [Resource Metadata](../core/resource_metadata.md) — field configuration the templates consume
