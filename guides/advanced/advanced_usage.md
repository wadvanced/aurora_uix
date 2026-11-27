# Advanced Usage

This guide covers advanced topics for customizing and extending Aurora UIX.

## How Templates Work

Templates are the core of Aurora UIX's code generation system. A template is a module that implements the `Aurora.Uix.Template` behaviour and is responsible for:

1. **Code Generation**: Converting layout configurations into LiveView modules
2. **Component Rendering**: Generating the HTML/component markup for different view types
3. **Event Handling**: Creating the logic for user interactions

The library ships one template, `Aurora.Uix.Templates.Basic`.

### Using Your Own Template

A template of your application implements the [callbacks](#template-callbacks). The shortest way to
start is to delegate to the Basic template and change what you need:

```elixir
defmodule MyAppWeb.AuixTemplate do
  @behaviour Aurora.Uix.Template

  alias Aurora.Uix.Templates.Basic

  @impl true
  def generate_module(parsed_opts), do: Basic.generate_module(parsed_opts)

  @impl true
  def layout_tags, do: Basic.layout_tags()

  @impl true
  def default_core_components_module, do: Basic.default_core_components_module()

  @impl true
  def default_theme_name, do: Basic.default_theme_name()
end
```

Configure it in `config/config.exs`:

```elixir
config :aurora_uix, :template, MyAppWeb.AuixTemplate
```

The setting is read at compile time, and one template serves the whole application.

To change only parts of the generated UI, you don't need a template: use
[component overrides](../customization/overriding_components.md),
[custom renderers](../core/resource_metadata.md#custom-field-types-and-rendering) or
[handler modules](../core/liveview.md#customizing-behavior).

### The Template Lifecycle

When a module calls `auix_create_ui`, Aurora UIX:

1. Takes the resources declared with `auix_resource_metadata`, with their parsed fields
2. Builds the render tree of each layout from the layouts you declared (see [Layout Structures](#layout-structures))
3. Calls the template's `generate_module/1` callback for each resource and layout type
4. The template returns the code of the modules for that layout type (index, show, form)

### Template Callbacks

A template module implements:

- **`generate_module(parsed_opts)`**: Returns the quoted code of the generated modules. It receives
  the options parsed for the resource, plus:
  - `:layout_type` - The layout being generated (`:index`, `:show` or `:form`)
  - `:layout_tree` - Its render tree, an `Aurora.Uix.Layout.Node` struct
  - `:resource_name` - The resource
  - `:configurations` - The configuration of every resource, with its fields in
    `configurations[resource_name].resource_config.fields`
  - `:modules` - Module references
  - `:artifacts`, `:used`, `:generate`, `:exposed_layouts` - Which modules to generate and under
    what names

- **`default_core_components_module()`**: Returns the module of the core UI components (forms,
  tables, buttons, modals, etc.) that your own modules import through `use Aurora.Uix.Renderer` or
  `use Aurora.Uix.CoreComponentsImporter`. The built-in renderers keep the Basic components when the
  template belongs to your application, because the library compiles first; replace those with
  [component overrides](../customization/overriding_components.md)

- **`layout_tags()`**: Returns the supported layout tags (`:index`, `:form`, `:show`)

- **`default_theme_name()`**: Returns the theme used when `:theme_name` is not configured; the
  Basic template returns `:white_charcoal`

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

### Layout Structures

The layout macros (`index_columns`, `edit_layout`, `show_layout`, `inline`, `stacked`, `group`,
`sections`, `section`) produce **layout nodes**, one struct per node kind under
`Aurora.Uix.Layout.Node` (`Index`, `Form`, `Show`, `Inline`, `Stacked`, `Group`, `Sections`,
`Section`, `Field`), holding what you wrote:

```elixir
%Aurora.Uix.Layout.Node.Form{
  resource: :product,
  children: [
    %Aurora.Uix.Layout.Node.Inline{
      children: [
        %Aurora.Uix.Layout.Node.Field{key: :name},
        %Aurora.Uix.Layout.Node.Field{key: :price}
      ]
    }
  ],
  options: [edit_title: "Edit product"]
}
```

At compile time each layout is built: the build fills in, on the same structs, what the
renderers need. Renderers receive the current node as `@auix.layout_tree` and dispatch on its
struct. The build adds:

- `id` - Built from the resource, the layout type and the node's position, so it is the same on every compile.
- `Field` nodes - `field` holds the resolved `Aurora.Uix.Field`: the resource field with the layout's options (`overrides`) merged over it.
- `Sections` and `Section` nodes - The tab state (`tabs`, `active?`, `sections_id`, `tab_index`, ...).
- `Index`, `Form` and `Show` nodes - `options` holds the layout options read through `Aurora.Uix.Layout.Options`, and `actions` holds the `*_action` entries.

A custom renderer reads a node's keys directly:

```elixir
def render(%{auix: %{layout_tree: %Aurora.Uix.Layout.Node.Group{title: title}}} = assigns) do
  ...
end
```

### Learning More About Conversions

The repository's tests show these conversions:

- `test/cases/resource_metadata_test.exs` - Resource metadata structures
- `test/cases/generation_test.exs` - Layouts and the generated modules

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
auix_resource_metadata :product_admin do
  context Inventory
  schema Product
  field :id, hidden: true
  field :reference, required: true, length: 50
  field :name, required: true, length: 200
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
auix_resource_metadata :product_customer do
  context Inventory
  schema Product
  field :reference, required: true
  field :name, required: true
  field :description
  field :list_price
  field :rrp
end

# Audit/logging metadata
auix_resource_metadata :product_audit do
  context Inventory
  schema Product
  field :reference
  field :inserted_at, readonly: true
  field :updated_at, readonly: true
end
```

A view module takes the resources it needs from the metadata module and generates its UI from
them:

```elixir
# Admin portal uses the admin representation
defmodule MyAppWeb.Admin.ProductViews do
  use Aurora.Uix

  alias MyAppWeb.Metadata.Inventory.Product, as: ProductMetadata

  @auix_resource_metadata %{product_admin: ProductMetadata.auix_resource(:product_admin)}

  auix_create_ui do
    index_columns(:product_admin, [:reference, :name, :quantity_at_hand, :list_price])
  end
end
```

The generated modules are named after the view module and the schema, so route this one with
`auix_live_resources("/products", Admin.ProductViews.Product)` inside your web scope.

### Accessing Separated Metadata

To access metadata defined in another module, use the `auix_resource/1` function:

```elixir
@auix_resource_metadata %{product: MyApp.ResourceMetadata.auix_resource(:product)}
```

`auix_resource/1` returns the resolved `%Aurora.Uix.Resource{}`. `@auix_resource_metadata` takes a map of
resources by name, so the view refers to the resource by that name.

### Introspecting generated UI modules

A module that calls `auix_create_ui` exposes functions that are useful for debugging and for tooling that inspects the generated UI structure:

- **`auix_layouts/0`** — returns the layouts as you defined them, before the build (excluding the defaults Aurora UIX injects automatically). Useful for verifying that custom layout macros were applied correctly.

  ```elixir
  MyAppWeb.Admin.ProductViews.auix_layouts()
  ```

- **`auix_configurations/0`** — returns the full configuration map from which all LiveView code is generated. This is the "fat" intermediate representation: fields, metadata, module references, and resolved options. Useful when debugging unexpected rendering or when building tooling on top of Aurora UIX.

  ```elixir
  MyAppWeb.Admin.ProductViews.auix_configurations()
  ```

- **`auix_modules/0`** — maps the names of the generated and the imported modules to the modules. `auix_module/1` returns one of them.

  ```elixir
  MyAppWeb.Admin.ProductViews.auix_modules()
  ```

A generated module, such as `MyAppWeb.Admin.ProductViews.Product.Index`, tells its kind with
`auix_kind/0` and the fields its layout places with `auix_fields/0`.

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
│   │   ├── product_views.ex
│   │   └── order_views.ex
│   ├── customer/                # (Who uses it - customers)
│   │   ├── product_views.ex
│   │   └── order_views.ex
│   └── public/                  # (Who uses it - public/guests)
│       └── catalog_views.ex
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
  use Aurora.Uix
  
  alias MyApp.Inventory
  alias MyApp.Inventory.Product

  # Admin representation - all fields including sensitive data
  auix_resource_metadata :product_admin do
    context Inventory
    schema Product
    field :id, hidden: true
    field :reference, required: true, length: 50
    field :name, required: true, length: 200
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
  auix_resource_metadata :product_customer do
    context Inventory
    schema Product
    field :reference, required: true
    field :name, required: true
    field :description
    field :list_price
    field :rrp
  end

  # Audit representation - only audit/tracking fields
  auix_resource_metadata :product_audit do
    context Inventory
    schema Product
    field :reference
    field :inserted_at, readonly: true
    field :updated_at, readonly: true
  end
end
```

Then use the metadata in views organized by role:

```elixir
# lib/my_app_web/live/admin/product_views.ex
# The admin role sees the full product information
defmodule MyAppWeb.Admin.ProductViews do
  use Aurora.Uix

  alias MyAppWeb.Metadata.Inventory.Product, as: ProductMetadata

  @auix_resource_metadata %{product_admin: ProductMetadata.auix_resource(:product_admin)}

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
end
```

```elixir
# lib/my_app_web/live/customer/product_views.ex
# The customer role sees only public product information
defmodule MyAppWeb.Customer.ProductViews do
  use Aurora.Uix

  alias MyAppWeb.Metadata.Inventory.Product, as: ProductMetadata

  @auix_resource_metadata %{product_customer: ProductMetadata.auix_resource(:product_customer)}

  auix_create_ui do
    index_columns(:product_customer, [:reference, :name, :list_price, :rrp])

    show_layout :product_customer do
      inline([:reference, :name])
      inline([:description])
      inline([:list_price, :rrp])
    end
  end
end
```

### Single vs Multiple Resources

A metadata module may describe one schema in several ways, as above, or group related schemas:

```elixir
# lib/my_app_web/metadata/inventory/catalog.ex
defmodule MyAppWeb.Metadata.Inventory.Catalog do
  use Aurora.Uix

  alias MyApp.Inventory
  alias MyApp.Inventory.Product
  alias MyApp.Inventory.ProductLocation

  auix_resource_metadata :product_admin, context: Inventory, schema: Product
  auix_resource_metadata :location_admin, context: Inventory, schema: ProductLocation
end
```

A view writes one `@auix_resource_metadata` line for each resource it takes:

```elixir
defmodule MyAppWeb.Admin.CatalogViews do
  use Aurora.Uix

  alias MyAppWeb.Metadata.Inventory.Catalog

  @auix_resource_metadata %{product_admin: Catalog.auix_resource(:product_admin)}
  @auix_resource_metadata %{location_admin: Catalog.auix_resource(:location_admin)}

  auix_create_ui()
end
```

A view that takes two resources over the same schema gives one of them its own module names; see
[Naming and reusing generated modules](../core/components.md#naming-and-reusing-generated-modules).

**Choose based on your preferences:**
- **Single module** - Good for small contexts with few schemas
- **Grouped module** - Good for related schemas (e.g., inventory catalog items)
- **Separate modules** - Good for large contexts or when schemas have complex, independent metadata

The repository's `test/support/mirror_web/variants/separated.ex` is a complete example.

## Defining Custom Backends

Besides the built-in Context (Ecto) and Ash integrations, you can connect Aurora UIX to another
data source: an external API, an in-memory store or another database library. A backend is made of
three modules:

| Module | Role |
|---|---|
| Fields parser | Describes the fields of a schema as `Aurora.Uix.Field` structs |
| Parser defaults | Returns one `Aurora.Uix.Integration.Connector` for each operation |
| CRUD | Implements the `Aurora.Uix.Integration.Crud` behaviour |

The example below keeps notes in memory. It covers listing, pagination, show, create, edit and
delete. It does not sort, filter or load associations.

### Step 1: The Record and Its Store

A schema is any struct module. It defines two `__schema__/1` clauses: Aurora UIX takes the paths
and stream names from `:source`, and identifies records by `:primary_key`.

```elixir
defmodule MyApp.Notes.Note do
  defstruct [:id, :title, :body]

  def __schema__(:source), do: "notes"
  def __schema__(:primary_key), do: [:id]
  def __fields__, do: [id: :string, title: :string, body: :string]
end
```

```elixir
defmodule MyApp.Notes.Store do
  use Agent

  def start_link(_opts), do: Agent.start_link(fn -> %{} end, name: __MODULE__)
  def all, do: __MODULE__ |> Agent.get(&Map.values/1) |> Enum.sort_by(& &1.title)
  def get(id), do: Agent.get(__MODULE__, &Map.get(&1, id))
  def put(note), do: Agent.update(__MODULE__, &Map.put(&1, note.id, note))
  def delete(id), do: Agent.update(__MODULE__, &Map.delete(&1, id))
end
```

Add `MyApp.Notes.Store` to your application's supervision tree.

### Step 2: The Fields Parser

```elixir
defmodule MyApp.MemoryBackend.FieldsParser do
  alias Aurora.Uix.Field

  def parse_fields(nil, _resource_name), do: []

  def parse_fields(schema, resource_name),
    do: Enum.map(schema.__fields__(), &parse_field(schema, resource_name, &1))

  # Also called by the index, for its selection column
  def parse_field(_schema, resource_name, {key, type}) do
    Field.new(%{
      key: key,
      type: type,
      html_type: html_type(type),
      name: to_string(key),
      label: key |> to_string() |> String.capitalize(),
      resource: resource_name,
      disabled: key == :id,
      filterable?: false,
      sortable?: false
    })
  end

  # No associations or embeds. The fields are expected back in reverse order.
  def parse_associations(_schema, _resource_name, _resources, fields), do: Enum.reverse(fields)
  def embedded_resource(_parent_resource, resources), do: resources
  def embedded_schema?(_schema), do: false

  defp html_type(:boolean), do: :checkbox
  defp html_type(:integer), do: :number
  defp html_type(_type), do: :text
end
```

### Step 3: The Parser Defaults

This module implements the `Aurora.Uix.Integration.ContextParserDefaults` behaviour. It returns a
connector whose second argument is the backend type. The first one is a map with whatever your CRUD
module needs to run the operation; the CRUD callbacks receive it.

```elixir
defmodule MyApp.MemoryBackend.ParserDefaults do
  @behaviour Aurora.Uix.Integration.ContextParserDefaults

  alias Aurora.Uix.Integration.Connector

  # The `backend_opts` the backend accepts
  @impl true
  def backend_opts_schema, do: []

  # Which of the operations to resolve
  @impl true
  def filter_options(operations, _resource_opts), do: operations

  @impl true
  def option_value(_parsed_opts, _resource_config, _opts, operation),
    do: Connector.new(%{operation: operation}, :memory)

  @impl true
  def fill_missing_options(parsed_opts, _resource_config), do: parsed_opts
end
```

The operations are `:list_function`, `:list_function_paginated`, `:get_function`,
`:create_function`, `:update_function`, `:delete_function`, `:change_function` and
`:new_function`.

### Step 4: The CRUD Module

The behaviour has nine callbacks:

```elixir
defmodule MyApp.MemoryBackend.Crud do
  @behaviour Aurora.Uix.Integration.Crud

  alias Aurora.Ctx.Pagination
  alias MyApp.Notes.Note
  alias MyApp.Notes.Store

  @types %{title: :string, body: :string}

  # The index reads pages; association lists and selects read everything
  @impl true
  def list(%{operation: :list_function_paginated}, opts) do
    %{page: page, per_page: per_page} = Keyword.fetch!(opts, :paginate)
    read_page(page, per_page)
  end

  def list(%{operation: :list_function}, _opts), do: Store.all()

  @impl true
  def to_page(_spec, %{pages_count: pages_count} = pagination, page, _opts)
      when page < 1 or page > pages_count,
      do: pagination

  def to_page(_spec, pagination, page, _opts), do: read_page(page, pagination.per_page)

  @impl true
  def get(_spec, id, _opts), do: Store.get(id)

  @impl true
  def new(_spec, attrs, _opts), do: struct(Note, attrs)

  @impl true
  def change(_spec, note, _form_name, attrs, _opts), do: changeset(note, attrs)

  @impl true
  def create(_spec, params, _opts),
    do: save(%Note{id: Integer.to_string(System.unique_integer([:positive]))}, params)

  @impl true
  def update(_spec, note, params, _opts), do: save(note, params)

  @impl true
  def delete(_spec, note, _opts) do
    Store.delete(note.id)
    {:ok, note}
  end

  # Options read from the socket and passed to the calls above, such as an actor
  @impl true
  def socket_opts(_spec, _socket), do: []

  defp changeset(note, attrs) do
    {note, @types}
    |> Ecto.Changeset.cast(attrs, Map.keys(@types))
    |> Ecto.Changeset.validate_required([:title])
  end

  defp save(note, params) do
    with {:ok, note} <- note |> changeset(params) |> Ecto.Changeset.apply_action(:save) do
      Store.put(note)
      {:ok, note}
    end
  end

  defp read_page(page, per_page) do
    notes = Store.all()
    count = length(notes)

    %Pagination{
      entries: Enum.slice(notes, (page - 1) * per_page, per_page),
      entries_count: count,
      pages_count: ceil(count / per_page),
      page: page,
      per_page: per_page
    }
  end
end
```

### Step 5: Register Your Backend

Register each module under your backend's type. The built-in `:ash` and `:ctx` backends stay
registered, so list only yours:

```elixir
# config/config.exs
config :aurora_uix, :crud_integration_modules, memory: MyApp.MemoryBackend.Crud

config :aurora_uix, :parser_defaults_integration_modules,
  memory: MyApp.MemoryBackend.ParserDefaults

config :aurora_uix, :fields_parser_integration_modules,
  memory: MyApp.MemoryBackend.FieldsParser
```

These keys are read when Aurora UIX compiles. An entry under a built-in key (`:ash` or `:ctx`)
replaces that built-in module.

### Step 6: Use Your Backend

Give the resource its `type`; it is not detected for a custom backend.

```elixir
defmodule MyAppWeb.NoteViews do
  use Aurora.Uix

  auix_resource_metadata :note do
    schema MyApp.Notes.Note
    type :memory
  end

  auix_create_ui do
    index_columns(:note, [:title, :body])

    edit_layout :note do
      stacked([:title, :body])
    end
  end
end
```

Route it like any other resource:

```elixir
auix_live_resources("/notes", NoteViews.Note)
```

### Beyond the Example

- **Sorting and filtering**: the list operations receive `:where` and `:order_by` options. Apply
  them before you mark a field `filterable?: true` or `sortable?: true`.
- **Associations and embeds**: `parse_associations/4` and `embedded_resource/2` describe them. See
  the built-in parsers.
- **Errors**: `create` and `update` return `{:error, changeset}` or `{:error, message}`.

The built-in backends are in `lib/aurora_uix/integration/ctx/` and
`lib/aurora_uix/integration/ash/`.

## Managing Actions

The content of this section has moved to its own guide:
[Custom Actions](../customization/custom_actions.md) — action groups by layout type,
the add/insert/replace/remove operations, action handlers, and processing order.

## Creating Custom Registered Themes

The content of this section has moved to its own guide:
[Creating Custom Registered Themes](../customization/theming.md) — the layered theme
architecture, `use Aurora.Uix.Templates.Theme`, light/dark modes, and theme registration.

## Related guides

- [Customizing & Extending Aurora UIX](../customization/customization.md) — the central customization hub
- [Custom Actions](../customization/custom_actions.md) — the action system reference
- [Creating Custom Registered Themes](../customization/theming.md) — theme authoring
- [Overriding Components](../customization/overriding_components.md) — runtime component replacement
- [Resource Metadata](../core/resource_metadata.md) — field configuration the templates consume
