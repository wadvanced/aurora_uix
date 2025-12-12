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

## Managing Actions

Actions are function components representing user interactions (buttons, links, etc.) attached to different parts of your views. Aurora UIX provides a comprehensive action system with support for adding, replacing, inserting, and removing actions via layout configuration.

### Understanding the Action System

Actions in Aurora UIX are defined in `Aurora.Uix.Action` and organized by **layout type** and **position**. Each action consists of:

- `:name` (atom) - Unique identifier for the action
- `:function_component` (function/1) - A component that renders the action

The action system works by:

1. **Setting defaults** - Template-specific modules add default actions (edit, delete, new, etc.)
2. **Removing defaults** - Via `remove_*_action` configuration
3. **Adding actions** - Via `add_*_action` configuration
4. **Inserting actions** - Via `insert_*_action` (prepends to list)
5. **Replacing actions** - Via `replace_*_action` (overrides existing by name)

### Available Action Groups

Actions are organized by layout type and position:

**Index View:**
- `:index_header_actions` - Top of table
- `:index_footer_actions` - Bottom of table
- `:index_row_actions` - Individual row actions
- `:index_selected_actions` - Actions for selected rows
- `:index_selected_all_actions` - Select all actions
- `:index_filters_actions` - Filter controls

**Form View:**
- `:form_header_actions` - Top of form
- `:form_footer_actions` - Bottom of form

**Show View:**
- `:show_header_actions` - Top of detail view
- `:show_footer_actions` - Bottom of detail view

**One-to-Many Associations:**
- `:one_to_many_header_actions` - Association table header
- `:one_to_many_footer_actions` - Association table footer
- `:one_to_many_row_actions` - Associated record row actions

**Embeds-Many Associations:**
- `:embeds_many_header_actions` - Embedded collection header
- `:embeds_many_footer_actions` - Embedded collection footer
- `:embeds_many_new_entry_actions` - New entry actions
- `:embeds_many_existing_actions` - Existing entry actions

### Configuring Actions via Layout DSL

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

### Action Handlers

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

### Association Actions

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

### How Actions Are Processed

The action system processes configuration in this order:

1. **Initialize** - Default actions are added by the template (index adds show/edit/delete, form adds save/cancel, etc.)
2. **Remove** - Specified actions are removed from their groups
3. **Add** - New actions are appended
4. **Insert** - Actions are prepended
5. **Replace** - Actions matching the name are replaced
6. **Finalize** - Layout options are applied via `Aurora.Uix.Templates.Basic.Actions.modify_actions/2`

See `Aurora.Uix.Action` module for the complete mapping of action names to their groups and helper functions.

## Creating Custom Registered Themes

Aurora UIX's theme system leverages Elixir's pattern matching and module composition to create flexible, composable CSS generation. Rather than hard-coding CSS, themes are Elixir modules that define rules dynamically, allowing you to create custom themes by extending base rules with your own color palettes and styling.

### Understanding the Theme Architecture

Aurora UIX themes follow a three-layer pattern:

**Layer 1: Color Palette**
- Defines all color variables for a specific theme variant
- Uses pattern matching to define `:root_colors` rule
- Implements both light and dark mode variants
- Theme-specific and forms the foundation
- Example: `VitreousMarble` theme with Slate/Cyan/Ruby colors

**Layer 2: Base Variables**
- Defines all structural CSS variables (sizes, spacing, fonts, shadows)
- Color-agnostic - contains only dimension and layout properties
- Delegates to Base for additional rules
- Example: `BaseVariables` defines `--auix-padding-default`, `--auix-border-radius-default`, etc.

**Layer 3: Base Rules**
- Defines all CSS class rules (`.auix-button`, `.auix-input`, etc.)
- Uses the color variables from Layer 1
- Shared across all themes
- Delegated through pattern matching for composition

### How It Works: Pattern Matching & Composition

Each theme module implements the `Aurora.Uix.Templates.Theme` behaviour with a `rule/1` function. This function uses pattern matching to return CSS for specific rule names:

```elixir
def rule(:root_colors) do
  # Returns CSS for color variables (Layer 1)
end

def rule(:root) do
  # Returns CSS for structural variables (Layer 2)
end

def rule(:_auix_button_default) do
  # Returns CSS for button styling (Layer 3)
end

def rule(other_rule) do
  # Delegate to parent theme
  SomeOtherTheme.rule(other_rule)
end
```

This pattern allows **composition**: each theme layer only defines what it needs, delegating everything else to the parent layer.

### Layer 1: Color Palette (Custom Theme)

Create your own theme by defining colors as the foundation:

```elixir
defmodule MyApp.Themes.CustomTheme do
  use Aurora.Uix.Templates.Theme, theme_name: :my_custom_theme
  
  alias Aurora.Uix.Templates.Basic.Themes.BaseVariables

  @impl true
  def rule(:root_colors) do
    """
    :root[data-theme-name="#{@theme_name}"],
    :host[data-theme-name="#{@theme_name}"] {
      /* Light Mode Colors (Default) */
      --auix-color-bg-default: #FFFFFF;
      --auix-color-bg-secondary: #F3F4F6;
      --auix-color-text-primary: #111827;
      --auix-color-text-secondary: #4B5563;
      --auix-color-error: #EF4444;
      --auix-color-info-ring: #3B82F6;
      
      /* Dark Mode Color Values (Stored as separate variables) */
      --dark--auix-color-bg-default: #0F172A;
      --dark--auix-color-bg-secondary: #1F2937;
      --dark--auix-color-text-primary: #F8FAFC;
      --dark--auix-color-text-secondary: #D1D5DB;
      --dark--auix-color-error: #EF5350;
      --dark--auix-color-info-ring: #64B5F6;
    }
    
    /* Apply Dark Mode via Media Query (respects OS preference) */
    @media (prefers-color-scheme: dark) {
      :root[data-theme-name="#{@theme_name}"],
      :host[data-theme-name="#{@theme_name}"] {
        --auix-color-bg-default: var(--dark--auix-color-bg-default);
        --auix-color-bg-secondary: var(--dark--auix-color-bg-secondary);
        --auix-color-text-primary: var(--dark--auix-color-text-primary);
        --auix-color-text-secondary: var(--dark--auix-color-text-secondary);
        --auix-color-error: var(--dark--auix-color-error);
        --auix-color-info-ring: var(--dark--auix-color-info-ring);
      }
    }
    
    /* Apply Dark Mode via Data Attribute (explicit override, highest priority) */
    :root[data-theme="dark"][data-theme-name="#{@theme_name}"],
    :host[data-theme="dark"][data-theme-name="#{@theme_name}"] {
      --auix-color-bg-default: var(--dark--auix-color-bg-default);
      --auix-color-bg-secondary: var(--dark--auix-color-bg-secondary);
      --auix-color-text-primary: var(--dark--auix-color-text-primary);
      --auix-color-text-secondary: var(--dark--auix-color-text-secondary);
      --auix-color-error: var(--dark--auix-color-error);
      --auix-color-info-ring: var(--dark--auix-color-info-ring);
    }
    """
  end

  # Delegate everything else to BaseVariables
  @impl true
  def rule(rule), do: BaseVariables.rule(rule)
end
```

**Key features**:
- `@theme_name` attribute automatically injected via `use` macro
- Define `:root_colors` rule with all color variables
- Light mode colors are defined directly in `:root[data-theme-name="..."]`
- Dark mode colors stored as `--dark--` prefixed variables in the same rule
- Use `@media (prefers-color-scheme: dark)` to switch colors based on OS preference
- Use `[data-theme="dark"]` selector for explicit dark mode override (highest priority)
- Delegate non-color rules to parent layer via pattern matching

### Understanding Light and Dark Modes

Aurora UIX uses a **light-first approach** with dark mode as an optional variant:

**How It Works**:
1. **Single CSS Rule** - One `:root[data-theme-name="..."]` rule defines everything
2. **Light Colors First** - Main color variables (e.g., `--auix-color-bg-default`) are set to light values by default
3. **Dark Color Storage** - Dark colors stored as `--dark--` prefixed variables (e.g., `--dark--auix-color-bg-default`)
4. **Conditional Switching** - Two CSS mechanisms reassign the main variables to dark values when needed

**Switching Mechanisms (Priority Order)**:

1. **Data Attribute** (Highest Priority)
   ```css
   :root[data-theme="dark"][data-theme-name="..."] {
     --auix-color-bg-default: var(--dark--auix-color-bg-default);
   }
   ```
   Explicit user override that always wins

2. **Media Query** (Medium Priority)
   ```css
   @media (prefers-color-scheme: dark) {
     --auix-color-bg-default: var(--dark--auix-color-bg-default);
   }
   ```
   Respects OS/browser dark mode preference

3. **Default Light** (Lowest Priority)
   ```css
   --auix-color-bg-default: #FFFFFF; /* Light default */
   ```
   No selector needed - this is the starting value

### Layer 2: Base Variables

The `BaseVariables` module defines all non-color CSS variables:

```elixir
defmodule Aurora.Uix.Templates.Basic.Themes.BaseVariables do
  use Aurora.Uix.Templates.Theme
  alias Aurora.Uix.Templates.Basic.Themes.Base

  @impl true
  def rule(:root) do
    """
    :root, :host {
      /* Sizes & Dimensions */
      --auix-box-size-unit: 1rem;
      --auix-border-radius-default: 0.5rem;
      --auix-padding-default: 0.625rem;
      
      /* Fonts */
      --auix-font-size-title: 1.125rem;
      --auix-font-family-default: var(--auix-font-sans);
      
      /* Shadows */
      --auix-shadow-default: 0 1px 3px 0 var(--auix-color-shadow-black-alpha);
    }
    """
  end

  # Delegate everything else to Base
  @impl true
  def rule(rule), do: Base.rule(rule)
end
```

**Key concept**: The `:root` rule defines all structural properties using CSS variables. These work together with the color variables from Layer 1 to create the complete theme.

### Creating a Simple Color Palette Theme

For a simple theme that only changes colors, you only need to define the color palette in Layer 1:

```elixir
defmodule MyApp.Themes.Ocean do
  use Aurora.Uix.Templates.Theme, theme_name: :ocean
  
  alias Aurora.Uix.Templates.Basic.Themes.BaseVariables

  @impl true
  def rule(:root_colors) do
    """
    :root[data-theme-name="#{@theme_name}"],
    :host[data-theme-name="#{@theme_name}"] {
      /* Light Mode (Default) */
      --auix-color-bg-default: #E0F2FE;      /* Sky-100 */
      --auix-color-bg-secondary: #BAE6FD;    /* Sky-200 */
      --auix-color-text-primary: #0C4A6E;    /* Sky-900 */
      --auix-color-text-secondary: #0369A1;  /* Sky-700 */
      --auix-color-error: #0EA5E9;           /* Sky-400 */
      --auix-color-focus-ring: #06B6D4;      /* Cyan-500 */
      
      /* Dark Mode Color Values */
      --dark--auix-color-bg-default: #082F49;
      --dark--auix-color-bg-secondary: #0C4A6E;
      --dark--auix-color-text-primary: #E0F2FE;
      --dark--auix-color-text-secondary: #38BDF8;
      --dark--auix-color-error: #38BDF8;
      --dark--auix-color-focus-ring: #06B6D4;
    }
    
    /* Apply Dark Mode via Media Query */
    @media (prefers-color-scheme: dark) {
      :root[data-theme-name="#{@theme_name}"],
      :host[data-theme-name="#{@theme_name}"] {
        --auix-color-bg-default: var(--dark--auix-color-bg-default);
        --auix-color-bg-secondary: var(--dark--auix-color-bg-secondary);
        --auix-color-text-primary: var(--dark--auix-color-text-primary);
        --auix-color-text-secondary: var(--dark--auix-color-text-secondary);
        --auix-color-error: var(--dark--auix-color-error);
        --auix-color-focus-ring: var(--dark--auix-color-focus-ring);
      }
    }
    
    /* Apply Dark Mode via Data Attribute (explicit override) */
    :root[data-theme="dark"][data-theme-name="#{@theme_name}"],
    :host[data-theme="dark"][data-theme-name="#{@theme_name}"] {
      --auix-color-bg-default: var(--dark--auix-color-bg-default);
      --auix-color-bg-secondary: var(--dark--auix-color-bg-secondary);
      --auix-color-text-primary: var(--dark--auix-color-text-primary);
      --auix-color-text-secondary: var(--dark--auix-color-text-secondary);
      --auix-color-error: var(--dark--auix-color-error);
      --auix-color-focus-ring: var(--dark--auix-color-focus-ring);
    }
    """
  end

  @impl true
  def rule(rule), do: BaseVariables.rule(rule)
end
```

This creates a complete ocean-blue theme with light and dark modes. All dimensions, fonts, shadows come from the parent layers.

**Using the Ocean theme**:

```html
<!-- Light mode (default) - no data-theme attribute needed -->
<html data-theme-name="ocean">

<!-- Dark mode via OS preference -->
<!-- Automatically uses dark colors if user's OS prefers dark mode -->
<html data-theme-name="ocean">

<!-- Dark mode via explicit attribute (overrides OS preference) -->
<html data-theme-name="ocean" data-theme="dark">

<!-- Light mode via explicit attribute (overrides OS preference) -->
<html data-theme-name="ocean" data-theme="light">
```

### Overriding Specific Rules

You can override individual CSS rules in Layer 3 while keeping everything else:

```elixir
defmodule MyApp.Themes.CompactTheme do
  use Aurora.Uix.Templates.Theme, theme_name: :compact
  
  alias Aurora.Uix.Templates.Basic.Themes.BaseVariables

  # Override the button styling
  @impl true
  def rule(:_auix_button_default) do
    """
    .-auix-button-default {
      display: flex;
      flex-direction: row;
      align-items: center;
      padding: 0.25rem 0.5rem;  /* More compact padding */
      font-size: 0.75rem;        /* Smaller font */
      border-radius: 0.25rem;    /* Tighter corners */
    }
    """
  end

  # Define colors
  @impl true
  def rule(:root_colors) do
    """
    :root[data-theme-name="#{@theme_name}"],
    :host[data-theme-name="#{@theme_name}"] {
      --auix-color-bg-default: #FFFFFF;
      --auix-color-text-primary: #000000;
      /* ... other colors ... */
    }
    """
  end

  # Delegate everything else
  @impl true
  def rule(rule), do: BaseVariables.rule(rule)
end
```

**Pattern matching allows you to**:
- Define custom rules for specific selectors
- Delegate to parent theme for everything else
- Incrementally customize without duplicating code

### Using Custom Themes

**Step 1: Create Your Theme Module**

Simply create a theme module that uses the `Aurora.Uix.Templates.Theme` macro:

```elixir
defmodule MyApp.Themes.Ocean do
  use Aurora.Uix.Templates.Theme, theme_name: :ocean
  
  # ... define your rule(:root_colors), etc.
end
```

**Step 2: Generate Stylesheet**

The build task `mix auix.gen.stylesheet` automatically:
- Discovers all theme modules in your application
- Collects all rules from each theme
- Generates a unified stylesheet with all themes

No manual registration needed!

```bash
mix auix.gen.stylesheet
```

**Step 3: Configure Default Theme**

Set the default theme in your application config:

```elixir
# config/config.exs
config :aurora_uix, theme_name: :ocean
```

**Step 4: Apply Theme to HTML**

The `AuixThemeName` hook automatically sets the `data-theme-name` attribute on the HTML element:

- **For Generated UI**: The hook is already included in all generated layouts
- **For Custom/Non-Generated UI**: Add the hook manually:

```elixir
# In your custom root layout template
<html phx-hook="AuixThemeName">
  <!-- content -->
</html>
```

The hook:
- Listens for `set_html_theme_name` events from the server
- Sets `data-theme-name` attribute to the configured theme
- Triggers CSS theme switching automatically

**Using Multiple Themes**

If you want to support theme switching at runtime:

```elixir
# In your view/controller
def handle_event("switch_theme", %{"theme" => theme_name}, socket) do
  {:noreply, push_event(socket, "set_html_theme_name", %{theme_name: theme_name})}
end
```

The CSS will automatically apply the correct theme based on the `data-theme-name` attribute.

### The Power of Pattern Matching

The real power comes from Elixir's pattern matching and module composition:

```elixir
defmodule MyApp.Themes.Advanced do
  use Aurora.Uix.Templates.Theme, theme_name: :advanced
  
  alias Aurora.Uix.Templates.Basic.Themes.BaseVariables

  # Custom rule for buttons
  def rule(:_auix_button_default), do: custom_button_styles()
  
  # Custom rule for inputs
  def rule(:_auix_input_default), do: custom_input_styles()
  
  # Custom colors
  def rule(:root_colors), do: custom_colors()
  
  # Everything else delegates
  def rule(rule), do: BaseVariables.rule(rule)

  defp custom_button_styles do
    # Your button CSS
  end

  defp custom_input_styles do
    # Your input CSS
  end

  defp custom_colors do
    # Your color variables
  end
end
```

This approach provides:
- **Composition**: Each layer adds its own rules
- **Overridability**: Replace any rule you want
- **Delegation**: Unused rules inherit from parent
- **Reusability**: Share base variables across themes
- **Maintainability**: Clear separation of concerns

### Real-World Example: Brand-Specific Theme

```elixir
defmodule MyApp.Themes.BrandTheme do
  use Aurora.Uix.Templates.Theme, theme_name: :brand
  
  alias Aurora.Uix.Templates.Basic.Themes.BaseVariables
  
  # Only override what's specific to your brand
  @impl true
  def rule(:root_colors) do
    """
    :root[data-theme-name="#{@theme_name}"],
    :host[data-theme-name="#{@theme_name}"] {
      /* Brand Colors */
      --auix-color-bg-default: #F9F5F0;        /* Brand cream */
      --auix-color-text-primary: #2C1810;      /* Brand dark brown */
      --auix-color-focus-ring: #C85A3A;        /* Brand orange */
      --auix-color-error: #D32F2F;
      --auix-color-info-ring: #1976D2;
      
      /* Shadows using brand colors */
      --auix-color-shadow-alpha: rgba(44, 24, 16, 0.08);
      
      /* Dark mode */
      --dark--auix-color-bg-default: #1A1208;
      --dark--auix-color-text-primary: #F9F5F0;
      --dark--auix-color-focus-ring: #FF9966;
    }
    """
  end

  @impl true
  def rule(rule), do: BaseVariables.rule(rule)
end
```

You define only the unique parts of your brand theme, and inherit all structural CSS from the base layers. This keeps your theme **small, focused, and maintainable**.

### References

For complete examples, see:
- `lib/aurora_uix/templates/basic/themes/vitreous_marble.ex` - Full theme implementation
- `lib/aurora_uix/templates/basic/themes/base_variables.ex` - Base variables definition
- `lib/aurora_uix/templates/basic/themes/base.ex` - Base CSS rules (2,296 lines of composition)

## Notes

- Only the callbacks listed in the Template behaviour are required and present in the default template implementation.
- The built-in `Aurora.Uix.Templates.Basic` is designed for extensibility - you can create wrappers or custom templates by referencing its structure.
- If you need custom markup or layout parsing, add additional functions to your template modules.
- The rendering pipeline is separated into handlers (event processing) and renderers (HTML generation) for flexible customization.
