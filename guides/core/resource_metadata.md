# Resource Metadata

Aurora UIX uses resource metadata to describe your data models and their UI behavior. This declarative system enables rich, metadata-driven UI configuration for Ecto schemas and custom data structures in Phoenix LiveView applications.

Resource metadata transforms schema definitions into complete UI configurations, automatically handling type inference, associations, and field rendering strategies.

## Overview

Resource metadata bridges the gap between data schema definitions and UI requirements. While schemas (Ecto or Ash) define data structure and validation rules, they don't contain presentation logic. Aurora UIX's metadata system adds UI-specific properties to fields and associations, enabling complete CRUD UI generation with minimal boilerplate.

Aurora UIX supports two backend types:

- **Context-based** - Traditional Phoenix Context modules with Ecto schemas
- **Ash Framework** - Ash resources with declarative actions and domains

## Key Concepts

### Resources

A **Resource** is the central configuration object that describes how a schema should be rendered in the UI. It maps a schema's fields and associations to field metadata that drives rendering and interaction.

### Fields and Associations

Fields and associations are the central elements driving UI rendering:

- **Fields** - Individual attributes mapped to HTML input elements (text, number, checkbox, etc.)
- **Associations** - Schema relationships that create complex UI interactions:
  - **Many-to-One** (`belongs_to`) - Rendered as select dropdowns with options
  - **One-to-Many** (`has_many`) - Rendered as nested lists with add/edit/delete actions
  - **Embeds** (`embeds_one`, `embeds_many`) - Nested schema structures rendered inline

### Configuration via Macro

The `auix_resource_metadata/3` macro provides a declarative interface for configuring both fields and associations with UI-specific properties. It processes the schema at compile-time, generating a `Aurora.Uix.Resource` struct with complete metadata.


## Metadata Generation Process

Resource metadata generation follows a multi-step compile-time process that adapts based on the backend type (Context-based or Ash Framework):

### Common Steps (Both Backends)

1. **Backend Detection** - Determines resource type (`:ctx` for Context-based, `:ash` for Ash Framework) based on provided options
2. **Configuration Application** - Applies user-defined customizations from the resource metadata block to fields
3. **Field Ordering** - Maintains field order as defined in configuration, with unconfigured fields appended at the end
4. **Finalization** - Converts field lists to maps for efficient runtime access and generates a `fields_order` list

### Context-based Resources (Ecto)

For traditional Phoenix Context modules with Ecto schemas:

1. **Schema Parsing** - Inspects schema fields, types, and associations at compile-time using Ecto's reflection API (`__schema__/1`, `__changeset__/0`)
2. **Field Initialization** - Creates `Aurora.Uix.Field` structs with default values based on Ecto types (`:string` → `:text`, `:boolean` → `:checkbox`, etc.)
3. **Association Processing** - Detects and configures:
   - `belongs_to` → Many-to-one associations (rendered as select dropdowns)
   - `has_many` → One-to-many associations (rendered as nested lists)
   - `embeds_one`/`embeds_many` → Embedded schemas (rendered inline)
4. **Context Function Discovery** - Infers CRUD function names from context module (e.g., `list_products/1`, `get_product/2`)

### Ash Framework Resources

For Ash resources with declarative actions:

1. **Resource Parsing** - Inspects Ash resource attributes, relationships, and actions using `Ash.Resource.Info` API
2. **Type Conversion** - Maps Ash types to Ecto-compatible types:
   - `Ash.Type.String` → `:string`
   - `Ash.Type.Integer` → `:integer`
   - `Ash.Type.Decimal` → `:decimal`
   - `Ash.Type.UtcDatetime` → `:utc_datetime`
   - Parameterized types and custom types are handled appropriately
3. **Field Initialization** - Creates `Aurora.Uix.Field` structs with Ash-specific metadata (constraints, validations)
4. **Relationship Processing** - Detects and configures:
   - `belongs_to` → Many-to-one relationships (rendered as select dropdowns)
   - `has_many` → One-to-many relationships (rendered as nested lists)
   - Embedded resources → Nested Ash resources (rendered inline with `__` naming convention)
5. **Action Resolution** - Discovers CRUD actions from Ash resource or domain:
   - Prioritizes primary actions (`:read`, `:create`, `:update`, `:destroy`)
   - Falls back to first available action of the required type
   - Validates pagination support for list operations
   - Creates function references wrapped in `Aurora.Uix.Integration.Connector` structs

### Embedded Resource Naming

Both backends follow a consistent naming pattern for embedded/associated resources:

- Parent resource: `:post`
- Embedded resource: `:post__comment` (double underscore notation)
- Nested embedded: `:post__comment__reply` (continues the pattern)

This compile-time generation ensures minimal runtime overhead while providing complete UI configuration through introspection, regardless of the backend framework used.

## Defining Resource Metadata

Use the `auix_resource_metadata/3` macro in your module. This macro accepts:
- `name` - A unique identifier for the resource (atom)
- `opts` - Configuration options for the resource backend
- `do` block - Field configuration using the `field/2` or `fields/2` macros

Aurora UIX supports two types of resource backends:

1. **Context-based Resources** - Traditional Phoenix Context modules with Ecto schemas
2. **Ash Framework Resources** - Ash resources and domains

### Context-based Resources

For traditional Ecto schemas with Phoenix Context modules:

- `:schema` (module()) - Required. Your Ecto schema module
- `:context` (module()) - Required. Context module with CRUD functions

### Ash Framework Resources

For Ash Framework resources:

- `:ash_resource` (module()) - Required. Your Ash resource module
- `:ash_domain` (module()) - Optional. Ash domain module containing the resource

When using Ash resources, you can also use `:schema` as an alias for `:ash_resource` 
and `:context` as an alias for `:ash_domain`.

Let's see examples for both approaches:

### Example Schema

```elixir
defmodule Aurora.Uix.Guides.Inventory.Product do
  use Ecto.Schema

  schema "products" do
    field(:reference, :string)
    field(:name, :string)
    field(:description, :string)
    field(:quantity_at_hand, :decimal)
    field(:quantity_initial, :decimal)
    field(:quantity_entries, :decimal)
    field(:quantity_exits, :decimal)
    field(:cost, :decimal)
    field(:msrp, :decimal)
    field(:rrp, :decimal)
    field(:list_price, :decimal)
    field(:discounted_price, :decimal)
    field(:weight, :decimal)
    field(:length, :decimal)
    field(:width, :decimal)
    field(:height, :decimal)
    field(:image, :binary)
    field(:thumbnail, :binary)
    field(:status, :string, default: "in_stock")
    field(:deleted, :boolean, default: false)
    field(:inactive, :boolean, default: false)

    timestamps()
  end

```

### Context-based Resource Configuration

To generate the resource metadata for a Context-based resource:

```elixir
defmodule MyAppWeb.ProductViews do
  use Aurora.Uix

  alias MyApp.Inventory
  alias MyApp.Inventory.Product

  auix_resource_metadata :product, context: Inventory, schema: Product do
    field :name, placeholder: "Product name", max_length: 40, required: true
    field :description, max_length: 255
    field :price, precision: 12, scale: 2, readonly: true
  end
end
```

### Ash Resource Configuration

For Ash Framework resources, use `:ash_resource` and optionally `:ash_domain`:

```elixir
defmodule MyAppWeb.BlogViews do
  use Aurora.Uix

  alias MyApp.Blog
  alias MyApp.Blog.Post
  alias MyApp.Blog.Author

  # With Ash domain
  auix_resource_metadata :post, 
    ash_resource: Post, 
    ash_domain: Blog do
    field :title, required: true, max_length: 100
    field :body, html_type: :textarea
    field :published_at, readonly: true
  end

  # Without domain (actions resolved from resource)
  auix_resource_metadata :author, ash_resource: Author do
    field :name, required: true
    field :bio, html_type: :textarea
  end
end
```

### Generated Resource Structure

The macro generates a `Aurora.Uix.Resource` struct containing:

- `name` - The resource identifier (`:product`)
- `schema` - The Ecto schema or Ash resource module
- `context` - Context module or Ash domain (optional)
- `type` - Backend type (`:ctx` for Context, `:ash` for Ash)
- `fields` - A map of field configurations by key
- `fields_order` - List of field keys in display order
- `opts` - Additional configuration options

**Example output:**

```elixir
%{
  product: %Aurora.Uix.Resource{
    name: :product,
    schema: Product,
    context: Inventory,
    type: :ctx,  # or :ash for Ash resources
    opts: [],
    fields: %{
      id: %Aurora.Uix.Field{key: :id, type: :binary_id, html_type: :text, ...},
      name: %Aurora.Uix.Field{key: :name, type: :string, html_type: :text, ...},
      description: %Aurora.Uix.Field{key: :description, type: :string, ...},
      product_location_id: %Aurora.Uix.Field{
        key: :product_location_id,
        type: :binary_id,
        html_type: :select,
        data: %{resource: :product_location, option_label: :name, ...}
      }
    },
    fields_order: [:id, :name, :description, :product_location_id, ...]
  }
}
```

### Backend Types

Aurora UIX automatically detects the backend type based on the options provided:

- **`:ctx`** - When using `:schema` and `:context` options with Ecto schemas
- **`:ash`** - When using `:ash_resource` (or Ash resource modules)

The backend type determines how CRUD operations are resolved:

- **Context backend** - Looks for functions like `list_products/1`, `get_product/2`, 
  `create_product/1` in the context module
- **Ash backend** - Resolves actions like `:read`, `:create`, `:update`, `:destroy` 
  from the Ash resource or domain

> **Note:** Aurora UIX's architecture supports custom backend implementations beyond Context
> and Ash. You can integrate other data layers or frameworks by implementing the required
> behaviours. See [Defining Custom Backends](../advanced/advanced_usage.md#defining-custom-backends)
> in the Advanced Usage guide for details.

- `Aurora.Uix.Resource` - Holds information about the resource to be rendered.
- `Aurora.Uix.Field` - Struct for the available field properties.

## Field Properties

Each field in the resource metadata is a `Aurora.Uix.Field` struct with the following properties:

### Field Metadata

- `key` - Schema's unique identifier for the field (atom)
- `name` - The field key as a binary string
- `type` - Ecto schema type (e.g., `:string`, `:integer`, `:decimal`, `:boolean`, `:utc_datetime`, 
    `:one_to_many_association`, `:many_to_one_association`, `:embeds_one`, `:embeds_many`)
- `html_type` - The HTML type inferred from Ecto type. Common values: `:text`, `textarea`, `:number`,
    `:checkbox`, `:select`, `:datetime-local`, `:time` 
    
- `resource` - Reference to the resource this field belongs to

### Display and Interaction

- `label` - Display label for the field (auto-generated from field name if not specified)
- `placeholder` - Placeholder text for input fields
- `html_id` - A unique HTML id for the field (auto-generated)
- `renderer` - Optional custom rendering function or component

### Validation and Constraints

- `length` - Maximum allowed length of input (typically 255 for strings)
- `precision` - Total number of digits for numeric fields (`:decimal`, `:float`)
- `scale` - Number of digits to the right of decimal separator for numeric fields
- `required` - If true, the field should not be empty
- `filterable?` - If true, the field can participate in filtering UI interfaces

### Presentation State

- `hidden` - If true, the field is included but not visible
- `readonly` - If true, the field should not accept changes (rendered but not editable)
- `disabled` - If true, the field does not participate in form interaction (appears disabled)
- `omitted` - If true, the field is completely excluded from the UI (as if it doesn't exist)

### Field Data

The `data` property is a versatile map that holds configuration specific to the field's purpose and type. Its structure varies depending on the field's functionality:

**For many-to-one associations (`:many_to_one_association`):**

- `resource` - The resource name of the related entity
- `owner_key` - The foreign key field on this schema
- `related` - The related schema module
- `related_key` - The primary key of the related entity
- `option_label` - Field name (atom), or function (arity 1 or 2) to generate dropdown labels
- `query_opts` - Optional keyword list with `:order_by` and `:where` clauses for filtering options

**For one-to-many associations (`:one_to_many_association`):**

- `resource` - The resource name of the related entities (may be `nil` if not configured)
- `owner_key` - The primary key on this schema
- `related` - The related schema module
- `related_key` - The foreign key field on the related schema

**For embedded schemas (`:embeds_one`, `:embeds_many`):**

- `owner` - The owner schema module
- `resource` - The embedded resource name (follows `parent__embed` naming pattern)
- `related` - The embedded schema module

**For select fields with fixed options:**

- `select` - Map containing:
  - `opts` - Keyword list of `{label, value}` pairs defining available options
  - `multiple` - Boolean indicating if multiple selection is allowed (default: `false`)

**For microsecond precision time fields (`:time_usec`, `:naive_datetime_usec`, `:utc_datetime_usec`):**

- `step` - Set to `1` to enable microsecond precision in HTML datetime inputs

**For other field types:**

- Empty map `%{}` when no special configuration is needed

## Custom Field Types and Rendering

You can specify custom HTML types and provide custom renderers for specialized field display:

```elixir
auix_resource_metadata :product, schema: MyApp.Product do
  field :status, html_type: :select, options: ["active", "inactive", "archived"]
  field :avatar, html_type: :image, renderer: &MyAppWeb.Helpers.render_avatar/1
end
```

The `html_type` option overrides the automatic HTML type inference. The `renderer` option allows providing a custom function or component for rendering the field.

## Associations

Aurora UIX supports four types of associations: **many_to_one** (`belongs_to`),  **one_to_many** (`has_many`), **embeds_one** and **embeds_many**. You can configure their behavior in the resource metadata.

### Automatic Association Detection

Association detection behavior depends on the backend implementation. The mapping described below corresponds to the current implemented backends (Context-based and Ash Framework).

Associations are automatically detected from your schema and converted to association fields:

- `belongs_to` → `many_to_one_association` type
- `has_many` → `one_to_many_association` type
- `embeds_one` → `embeds_one` type
- `embeds_many` → `embeds_many` type

Custom backend implementations may provide different association detection mechanisms while maintaining compatibility with Aurora UIX's rendering system.

### Many-to-One (belongs_to)

By default, if a field represents a many-to-one association, if the foreign key field is used with `:select` html_type, association is rendered as a dropdown. You can customize this behavior.

The `option_label` option controls what is shown as the label for each option in the dropdown. It supports three patterns:

**Usage:**

- **As an atom (field name)** - Use a single field from the related entity:
  ```elixir
  field :category_id, html_type: :select, option_label: :name
  ```
  This will use the `:name` field of the related entity as the label in the dropdown.:what

- **As a function (arity 1)** - Use a custom function to generate labels:
  ```elixir
  field :category_id, html_type: :select, option_label: &MyApp.Category.label/1
  ```
  The function receives the entity instance and should return a string label.

- **As a function (arity 2)** - Use a function that receives both assigns and the entity:
  ```elixir
  # In your Category module:
  def label(assigns, category) do
    "#{assigns.prefix}_#{category.code} - #{category.name}"
  end
  ```
  ```elixir
  field :category_id, html_type: :select, option_label: &MyApp.Category.label/2
  ```

### Query Options for Many-to-One

When `option_label` is set to a field reference (atom), you can also specify query options:

- `:order_by` - Controls the ordering of options in the dropdown
- `:where` - Filters the options to display

**Examples:**

```elixir
# Renders a selector displaying names ordered ascending
auix_resource_metadata :product, schema: MyApp.Product do
  field :category_id, html_type: :select, option_label: :name, order_by: :name
end
```

```elixir
# Renders a selector with filtered options ordered descending by reference
auix_resource_metadata :product, context: Inventory, schema: Product do
  field :category_id, option_label: :name, 
    order_by: [desc: :reference], 
    where: [{:name, :between, "A", "Z"}]
end
```

### One-to-Many (has_many)

Fields representing a **one-to-many** (`has_many`) association are rendered as a list with customizable actions for adding, editing, and deleting items. You can sort and filter the list.

**Available options:**

- `:order_by` - Changes the order of how elements are initially rendered. Follows Ecto's order_by syntax.
- `:where` - Defines filtering. Follows Ecto's where syntax.

**Example:**

```elixir
auix_resource_metadata :product, schema: MyApp.Product do
  field :product_transactions, 
    order_by: [desc: :quantity], 
    where: {:quantity, :between, 8, 16}
end
```




