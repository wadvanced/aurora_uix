# Resource Metadata

Aurora UIX uses resource metadata to describe your data models and their UI behavior. This declarative system enables rich, metadata-driven UI configuration for Ecto schemas and custom data structures in Phoenix LiveView applications.

Resource metadata transforms schema definitions into complete UI configurations, automatically handling type inference, associations, and field rendering strategies.

## Overview

Resource metadata bridges the gap between Ecto schema definitions and UI requirements. While Ecto schemas define data structure and validation rules, they don't contain presentation logic. Aurora UIX's metadata system adds UI-specific properties to fields and associations, enabling complete CRUD UI generation with minimal boilerplate.

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

Resource metadata generation follows a multi-step compile-time process:

1. **Schema Parsing** - Inspects schema fields, types, and associations at compile-time using Ecto's reflection API
2. **Field Initialization** - Creates `Aurora.Uix.Field` structs with default values based on Ecto types (`:string` → `:text`, `:boolean` → `:checkbox`, etc.)
3. **Configuration Application** - Applies user-defined customizations from the resource metadata block to fields
4. **Association Processing** - Adds association metadata and configures many-to-one selectors with proper linking
5. **Field Ordering** - Maintains field order as defined in configuration, with unconfigured fields appended at the end
6. **Finalization** - Converts field lists to maps for efficient runtime access and generates a `fields_order` list

This compile-time generation ensures minimal runtime overhead while providing complete UI configuration through introspection.

## Defining Resource Metadata

Use the `auix_resource_metadata/3` macro in your module. This macro accepts:
- `name` - A unique identifier for the resource (atom)
- `opts` - Configuration options including required `:schema` and optional `:context`
- `do` block - Field configuration using the `field/2` or `fields/2` macros

Let's see an example:

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

To generate the resource metadata using the `auix_resource_metadata` macro:

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

### Generated Resource Structure

The macro generates a `Aurora.Uix.Resource` struct containing:

- `name` - The resource identifier (`:product`)
- `schema` - The Ecto schema module
- `context` - Optional context module
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

- `Aurora.Uix.Resource` - Holds information about the resource to be rendered.
- `Aurora.Uix.Field` - Struct for the available field properties.

## Field Properties

Each field in the resource metadata is a `Aurora.Uix.Field` struct with the following properties:

### Field Metadata

- `key` - Schema's unique identifier for the field (atom)
- `name` - The field key as a binary string
- `type` - Ecto schema type (e.g., `:string`, `:integer`, `:decimal`, `:boolean`, `:utc_datetime`)
- `html_type` - The HTML type inferred from Ecto type. Common values: `:text`, `:number`, `:checkbox`, `:select`, `:datetime-local`, `:time`, `:one_to_many_association`, `:many_to_one_association`
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

### Association Data

For association fields, the `data` property contains:

- `resource` - The resource name of the related entity
- `owner_key` - The foreign key field on this schema
- `related` - The related schema module
- `related_key` - The primary key of the related entity
- `option_label` - (many-to-one only) Field/function to display as the label in dropdown
- `query_opts` - (many-to-one only) Keyword list with `:order_by` and `:where` clauses

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

Associations are automatically detected from your schema and converted to association fields:

- `belongs_to` → `many_to_one_association` html_type
- `has_many` → `one_to_many_association` html_type
- `embeds_one` → `embeds_one` html_type
- `embeds_many` → `embeds_many` html_type

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




