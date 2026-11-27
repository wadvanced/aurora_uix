# Resource Metadata

Aurora UIX uses resource metadata to describe your data models and their UI behavior. This declarative system enables rich, metadata-driven UI configuration for Ecto schemas and custom data structures in Phoenix LiveView applications.

Resource metadata transforms schema definitions into complete UI configurations, automatically handling type inference, associations, and field rendering strategies.

## Overview

Resource metadata bridges the gap between data schema definitions and UI requirements. While schemas (Ecto or Ash) define data structure and validation rules, they don't contain presentation logic. Aurora UIX's metadata system adds UI-specific properties to fields and associations, enabling complete CRUD UI generation with minimal boilerplate.

Aurora UIX supports two backend types:

- **Context-based** - Traditional Phoenix Context modules with Ecto schemas
- **Ash Framework** - Ash resources with declarative actions

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

The `auix_resource_metadata` macro provides a declarative interface for configuring both fields and associations with UI-specific properties. It processes the schema at compile-time, generating a `Aurora.Uix.Resource` struct with complete metadata.


## Metadata Generation Process

Resource metadata generation follows a multi-step compile-time process that adapts based on the backend type (Context-based or Ash Framework):

### Common Steps (Both Backends)

1. **Backend Detection** - Determines the resource type from the schema module: `:ash` for an Ash resource, `:ctx` for an Ecto schema. The `:type` option overrides it
2. **Configuration Application** - Applies user-defined customizations from the resource metadata block to fields
3. **Field Ordering** - Keeps the order the schema declares, with associations after the other fields. The order of the `field` entries does not change it; a `field` entry for a key the schema lacks is appended at the end. Use a [layout](layouts.md) to choose what each view shows and in which order
4. **Finalization** - Converts field lists to maps for efficient runtime access and generates a `fields_order` list

### Context-based Resources (Ecto)

For traditional Phoenix Context modules with Ecto schemas:

1. **Schema Parsing** - Inspects schema fields, types, and associations at compile-time using Ecto's reflection API (`__schema__/1`, `__changeset__/0`)
2. **Field Initialization** - Creates `Aurora.Uix.Field` structs with default values based on Ecto types (`:string` → `:text`, `:boolean` → `:checkbox`, etc.)
3. **Association Processing** - Detects and configures:
   - `belongs_to` → Many-to-one associations (rendered as select dropdowns)
   - `has_many` → One-to-many associations (rendered as nested lists)
   - `has_one` → One-to-one associations
   - `many_to_many` → Many-to-many associations (rendered as multi-selects)
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
   - `has_one` → One-to-one relationships
   - `many_to_many` → Many-to-many relationships (rendered as multi-selects)
   - Embedded resources → Nested Ash resources, rendered inline (see [Embedded Resources](#embedded-resources))
5. **Calculations and Aggregates** - Discovers Ash calculations and aggregates and parses them into fields. A calculation takes its declared type and an aggregate the type Ash resolves for it (for example `count → :integer`, `exists → :boolean`; a `sum` or a `max` follows the aggregated field). Both are disabled in forms. Fields whose type can't be inferred can be overridden via the metadata block — see [Calculations and Aggregates](ash_integration.md#calculations-and-aggregates).
6. **Action Resolution** - Discovers CRUD actions from Ash resource:
   - Prioritizes primary actions (`:read`, `:create`, `:update`, `:destroy`)
   - Falls back to first available action of the required type
   - Validates pagination support for list operations
   - Creates function references wrapped in `Aurora.Uix.Integration.Connector` structs

### Embedded Resources

An embedded field (`embeds_one`, `embeds_many`, an Ash attribute whose type is an embedded
resource) is rendered with a resource that describes the embedded schema. The library creates one
for every embedded field, named `<parent>__<field>`:

- Parent resource: `:post`
- Resource created for its `comment` field: `:post__comment`

To set field options for the embedded record, declare a resource on the embedded schema and name
it in the parent with `resource:`:

```elixir
auix_resource_metadata :employer do
  ash_resource Employer
  field :legal_rep, resource: :legal_contact
  field :hr_manager, resource: :hr_contact
end

auix_resource_metadata :legal_contact do
  ash_resource Contact
  field :phone, required: true
end

auix_resource_metadata :hr_contact, ash_resource: Contact
```

Without `resource:` an embedded field uses the resource named `<parent>__<field>`: the one the
module declares under that name, else the one the library creates.

The backend decides whether a schema is embedded-only: an Ash resource with
`data_layer: :embedded`, and an Ecto schema without a table (`embedded_schema`, and the inline
schema of `embeds_one` and `embeds_many`). A resource on such a schema generates no modules,
whatever its name, and on the Ecto backend it needs no `context:`.

An Ecto schema with a table can also be embedded. A resource declared on it is a standalone
resource: it needs `context:` with its CRUD functions and generates its modules. Remove the
declaration to use the resource the library creates.

`resource:` is checked when the module compiles: the name must be a resource of the module,
declared or imported; that resource must describe the schema the field relates to; and the field
must be an embedded field or an association.

This compile-time generation ensures minimal runtime overhead while providing complete UI configuration through introspection, regardless of the backend framework used.

## Defining Resource Metadata

Use `auix_resource_metadata` in your module. It accepts:
- `name` - A unique identifier for the resource (atom)
- options - Configuration options for the resource backend, either as a keyword list
  (`auix_resource_metadata :product, schema: Product, context: Inventory`) or, when fields
  are configured, as calls inside the `do` block (`schema Product`)
- `do` block - Field configuration using `field` or `fields`

Options are validated at compile time: an unknown or mistyped option fails compilation
with the line that declares it.

Aurora UIX supports two types of resource backends:

1. **Context-based Resources** - Traditional Phoenix Context modules with Ecto schemas
2. **Ash Framework Resources** - Ash resources

### Context-based Resources

For traditional Ecto schemas with Phoenix Context modules:

- `:schema` (module()) - Required. Your Ecto schema module
- `:context` (module()) - Context module with CRUD functions. Required unless the schema has no table (see [Embedded Resources](#embedded-resources))

### Ash Framework Resources

For Ash Framework resources:

- `:ash_resource` (module()) - Required. Your Ash resource module
- `:ash_actor_assign` (atom()) - Optional, inside `backend_opts`. Name of the
  `socket.assigns` key that holds the actor used to authorize policy-protected
  resources. Default `nil` (no `actor:` forwarded). When set, every CRUD call
  generated by Aurora UIX receives `actor: socket.assigns[<assign>]`.
  `:actor_assign` is accepted as an alias.

  ```elixir
  auix_resource_metadata :template,
    ash_resource: MyApp.Templates.InterfaceDocumentTemplate,
    backend_opts: [ash_actor_assign: :current_user]
  ```

  See [Ash Integration → Authorization and policies](ash_integration.md#authorization-and-policies)
  for the worked example, troubleshooting checklist, and the full behaviour
  matrix.

When using Ash resources, you can also use `:schema` as an alias for `:ash_resource` 

### Index Query Options

A resource can shape the query behind its index list. An `index_columns` layout can set the same
options for one layout, and the layout's value replaces the resource's.

- `:order_by` - Initial order of the entries, in `Ecto.Query.order_by/3` form.
- `:where` - Filter of the entries. Conditions submitted from the filter bar are added to it.
- `:preload` (list()) - Associations the index list loads besides the ones its layout renders, for
  an `option_label` function, a custom renderer or a hook that reads them. Entries are association
  names or nested keyword lists, such as `[:category, posts: :author]`. It works on both backends.

```elixir
auix_resource_metadata :product do
  context Inventory
  schema Product
  order_by :reference
  preload [:product_location]
end
```

### Display Name and Title

Both backends accept two optional presentation options, independent of the resource's
identifier (the macro's first positional `name` argument):

- `:name` (`binary()` or 0-arity `function()`) - Optional. The resource's display name, used
  to build default titles and action labels (e.g. `"New {name}"`, `"Edit {name}"`). Defaults
  to the capitalized schema module name (e.g. `MyApp.Product` → `"Product"`).
- `:title` (`binary()` or 0-arity `function()`) - Optional. The resource's display title, used
  in other title/subtitle defaults (e.g. `"Listing {title}"`, `"Back to {title}"`). Defaults
  to the capitalized schema source/table name (e.g. `"products"` → `"Products"`).

In addition to a plain `binary()`, both options accept a captured 0-arity function returning a
`binary()`, evaluated wherever the default is built:

```elixir
auix_resource_metadata :product,
  schema: MyApp.Inventory.Product,
  context: MyApp.Inventory,
  name: "Product",
  title: &MyApp.Inventory.Product.display_title/0
```

This is a different mechanism from the arity-1, `assigns`-receiving functions accepted by
per-layout title/subtitle options (`:page_title`, `:edit_title`, and similar) — see
[Layout System → Dynamic Titles and Subtitles](layouts.md#dynamic-titles-and-subtitles) for that.

Let's see examples for both approaches:

### Example Schema

```elixir
defmodule MyApp.Inventory.Product do
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
end
```

### Context-based Resource Configuration

To generate the resource metadata for a Context-based resource:

```elixir
defmodule MyAppWeb.ProductViews do
  use Aurora.Uix

  alias MyApp.Inventory
  alias MyApp.Inventory.Product

  auix_resource_metadata :product do
    context Inventory
    schema Product
    field :name, placeholder: "Product name", length: 40, required: true
    field :description, length: 255
    field :list_price, precision: 12, scale: 2, readonly: true
  end
end
```

### Ash Resource Configuration

For Ash Framework resources, use `:ash_resource`:

```elixir
defmodule MyAppWeb.BlogViews do
  use Aurora.Uix

  alias MyApp.Blog.Author

  auix_resource_metadata :author do
    ash_resource Author
    field :name, required: true
    field :bio, html_type: :textarea
  end
end
```

### Generated Resource Structure

The macro generates a `Aurora.Uix.Resource` struct containing:

- `name` - The resource identifier (`:product`)
- `schema` - The Ecto schema or Ash resource module
- `context` - Context module
- `type` - Backend type (`:ctx` for Context, `:ash` for Ash)
- `order_by`, `where`, `preload` - As declared (see [Index Query Options](#index-query-options))
- `renderers` - The resource-level `:renderers` option: an `html_type => renderer` table applied to
  every field of the resource. Per-field renderers (`renderer`, `index_renderer`, `edit_renderer`,
  `show_renderer`) stay on each `Aurora.Uix.Field`
- `display_name`, `title` - The `:name` and `:title` options
- `backend_opts` - Options owned by the backend, such as `:ash_actor_assign` or the CRUD
  action and function overrides
- `field_overrides` - The `field` entries as partial `Aurora.Uix.Field` structs: unset options
  are `nil` and `resolved?` is `false`
- `fields` - A map of field configurations by key, each with `resolved?: true`
- `fields_order` - List of field keys in display order
- `resolved?` - `true` once the schema is parsed and the defaults are filled

**Example output**, abridged:

```elixir
%{
  product: %Aurora.Uix.Resource{
    name: :product,
    schema: MyApp.Inventory.Product,
    context: MyApp.Inventory,
    type: :ctx,
    order_by: nil,
    renderers: %{},
    backend_opts: [],
    fields: %{
      name: %Aurora.Uix.Field{key: :name, type: :string, html_type: :text},
      product_location_id: %Aurora.Uix.Field{
        key: :product_location_id,
        type: :binary_id,
        html_type: :select,
        option_label: nil,
        data: %{resource: :product_location}
      }
    },
    fields_order: [:id, :name, :product_location_id]
  }
}
```

### Backend Types

Aurora UIX detects the backend type from the schema module, whichever option names it
(`:schema` or `:ash_resource`):

- **`:ctx`** - The module is an Ecto schema. It also needs `:context`
- **`:ash`** - The module is an Ash resource

The backend type determines how CRUD operations are resolved:

- **Context backend** - Looks for functions like `list_products/1`, `get_product/2`, 
  `create_product/1` in the context module
- **Ash backend** - Resolves actions like `:read`, `:create`, `:update`, `:destroy` 
  from the Ash resource

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
    `:one_to_many_association`, `:many_to_one_association`, `:one_to_one_association`,
    `:many_to_many_association`, `:embeds_one`, `:embeds_many`)
- `html_type` - The HTML type inferred from Ecto type. Common values: `:text`, `textarea`, `:number`,
    `:checkbox`, `:select`, `:datetime-local`, `:time` 
    
- `resource` - Name of the resource that owns the field. The `resource:` field option does not change it: it sets `data.resource` (see [Field Data](#field-data))

### Display and Interaction

- `label` - Display label for the field (auto-generated from field name if not specified)
- `placeholder` - Placeholder text for input fields
- `html_id` - A unique HTML id for the field (auto-generated)
- `renderer` - Optional custom rendering function or component, applied to the **form (edit)** and **show** layouts unless a more specific per-layout renderer is set
- `index_renderer` - Optional custom rendering function or component, applied only to the **index** layout (does not fall back to `renderer`)
- `edit_renderer` - Optional custom rendering function or component, applied only to the **form (edit)** layout (falls back to `renderer` when not set)
- `show_renderer` - Optional custom rendering function or component, applied only to the **show** layout (falls back to `renderer` when not set)

### Validation and Constraints

- `length` - Maximum allowed length of input (typically 255 for strings)
- `precision` - Total number of digits for numeric fields (`:decimal`, `:float`)
- `scale` - Number of digits to the right of decimal separator for numeric fields
- `required` - If true, the field should not be empty
- `filterable?` - If true, the field can participate in filtering UI interfaces
- `generated?` - If true, the value is not stored with the entity (an Ash calculation or aggregate) and is loaded with it
  wherever a layout renders the field. The Ash parser detects the calculations and aggregates of a resource; declare it for
  any other field that needs the same load. `data: %{generated: true}` is no longer accepted
- `sortable?` - If true, the index column header offers sorting. The parser sets it from the column type; fields no parser produced default to `false`

### Presentation State

- `hidden` - If true, the field is included but not visible
- `readonly` - If true, the field should not accept changes (rendered but not editable)
- `disabled` - If true, the field does not participate in form interaction (appears disabled)
- `omitted` - If true, the field is completely excluded from the UI (as if it doesn't exist)

### Selector, Embed and Upload Options

These field options have their own keys on `Aurora.Uix.Field`:

- `option_label` - For many-to-one and many-to-many selectors: the field name (atom) shown for each
  option, or a function of arity 1 (`entity`) or 2 (`assigns`, `entity`) returning the label
- `query_opts` - Keyword list with `:order_by` and `:where`, applied when listing the options of a
  many-to-one or many-to-many selector, or the rows of a one-to-many list (see
  [One-to-Many](#one-to-many-has_many))
- `resource` - (embedded fields and associations) The name of the resource that renders the
  related entries, kept in `data.resource`. On an association it also preloads the association
  fields that the layouts of the named resource render (see
  [Preloading Associations](liveview.md#preloading-associations)). See
  [Embedded Resources](#embedded-resources) and
  [Two resources on one schema](components.md#two-resources-on-one-schema)
- `upload` - An `Aurora.Uix.Field.Upload` with the upload options described under
  "For file-upload fields" below
- `expanded` - (`:embeds_many` only) Controls whether the embedded collection renders expanded or
  collapsed on initial load, in both show and edit modes. Defaults to `false` (collapsed). Accepts a
  boolean or a captured function of arity 1 (`&MyApp.fun/1`, not an inline `fn` — field options are
  escaped at compile time) that receives the rendering assigns and returns a boolean. The runtime
  collapse/expand toggle stays available regardless. Configure it with the `:expanded` field option
  of the resource metadata, or on the field in an `edit_layout` or `show_layout`, which takes
  precedence in that view:

  ```elixir
  # Always expanded
  field :addresses, expanded: true

  # Expanded conditionally, based on the rendering assigns
  field :addresses, expanded: &MyApp.Inventory.addresses_expanded?/1
  ```

### Field Data

The `data` property is a versatile map that holds configuration specific to the field's purpose and type. The backend parser fills it; the only key a host may set is `select`, to override the choices of a select field. Its structure varies depending on the field's functionality:

**For many-to-one associations (`:many_to_one_association`):**

- `resource` - The resource name of the related entity: the one `resource:` names, else the latest resource declared for the related schema
- `owner_key` - The foreign key field on this schema
- `related` - The related schema module
- `related_key` - The primary key of the related entity

**For one-to-many associations (`:one_to_many_association`):**

- `resource` - The resource name of the related entities: the one `resource:` names, else the latest resource declared for the related schema (`nil` when there is none)
- `owner_key` - The primary key on this schema
- `related` - The related schema module
- `related_key` - The foreign key field on the related schema

**For embedded schemas (`:embeds_one`, `:embeds_many`):**

- `owner` - The owner schema module
- `resource` - The name of the resource that renders the embedded record: the one `resource:` names, else `<parent>__<field>`
- `related` - The embedded schema module

**For select fields with fixed options:**

- `select` - Map containing:
  - `opts` - Keyword list of `{label, value}` pairs defining available options
  - `multiple` - Boolean indicating if multiple selection is allowed (default: `false`)

**For microsecond precision time fields (`:time_usec`, `:naive_datetime_usec`, `:utc_datetime_usec`):**

- `step` - Set to `1` to enable microsecond precision in HTML datetime inputs

**For other field types:**

- Empty map `%{}` when no special configuration is needed

### File Uploads

Add an `upload` block to a field to turn it into a managed LiveView upload field. The
options are stored in the field's `upload` key:

```elixir
auix_resource_metadata :template do
  context MyApp.Templates
  schema MyApp.Template

  field :uploaded_blob_ref do
    upload allow: [accept: ~w(.xlsx), max_entries: 1, max_file_size: 5_000_000],
           consume: &MyApp.Templates.store_xlsx/1
  end
end
```

- `:allow` — keyword list forwarded verbatim to `Phoenix.LiveView.allow_upload/3`.
  Supports `:accept`, `:max_entries`, `:max_file_size`, `:auto_upload?`, and any other
  option that `allow_upload/3` accepts.
- `:consume` — callback receiving `[binary()]` (the read bytes of each selected file). It accepts
  arity 1 (`binaries`), 2 (`socket, binaries`) or 3 (`socket, binaries, key`).
  Return values:
  - `{:ok, value}` — `value` is written onto the entity params under the field key before save.
  - `:no_change` — the field is left untouched; the helper also short-circuits to `:no_change`
    when no file is selected, so the callback need not handle an empty list.
  - `{:error, reason}` — save aborts and `reason` is displayed as an error flash.
- `:download` — **optional** producer callback invoked when the user clicks the Download button
  on show and edit views. It produces the file; the button shows through `:downloadable?`. Accepts
  arity 1, 2, or 3:
  - Arity 1: `download.(value)` — field value only.
  - Arity 2: `download.(socket, value)` — socket available for actor/assign access.
  - Arity 3: `download.(socket, value, key)` — one callback handles multiple upload fields.
  Return values:
  - `{:ok, %{name: filename, content: binary}}` — triggers a client-side file download.
  - `:no_download` — does nothing (button click is a no-op).
  - `{:error, reason}` — displays `reason` as an error flash.
- `:downloadable?` — a boolean, or a callback evaluated when the component mounts or updates, that
  controls whether the Download button is visible. It is only read when `:download` is also set:
  without `:download` no button is rendered and the callback is not invoked. A callback accepts arity 1, 2, or 3 (same dispatch as `:download`) and must return a boolean.
  **When omitted, the button is hidden**: set `downloadable?: true` to show it always, or use a
  callback such as one that checks the value is not `nil`.
- `:file_info` — **optional** callback describing the stored file, evaluated when the component
  mounts or updates and only when the field holds a value. It accepts arity 1, 2, or 3 (same
  dispatch as `:download`) and returns a map with any of `:name` (binary), `:size` (bytes) and
  `:content_type` (binary), or `nil`:

  ```elixir
  field :uploaded_blob_ref do
    upload allow: [accept: ~w(.xlsx), max_entries: 1],
           consume: &MyApp.Templates.store_xlsx/1,
           download: &MyApp.Templates.fetch_xlsx/1,
           downloadable?: true,
           file_info: &MyApp.Templates.xlsx_info/1
  end

  # in MyApp.Templates
  def xlsx_info(ref), do: %{name: "#{ref}.xlsx", size: blob_size(ref), content_type: "application/xlsx"}
  ```

A stored file is shown as a card: a file icon, the name from `:file_info` (or the field label when
there is none), its type and size when given, a download button when the field is downloadable and,
in the form, a replace button that opens the file picker. A field without a value shows "No file"
on the show page and a "Choose file" button with the accepted types in the form. Selected files are
listed as cards with their progress and a cancel button. The field container carries
`data-upload-field` with the field key, and the card is styled by the theme's `auix-upload-*` rules.

Aurora UIX handles the full lifecycle automatically: `allow_upload` registration (guarded
against double registration on re-renders), `live_file_input` rendering (visually hidden, opened by the "Choose file" and replace
buttons) with per-entry
progress, cancel buttons, upload/entry-level error display, and client-side download dispatch
via the `phx:auix_download` event (requires `hooks.js` — see the Getting Started guide).

## Custom Field Types and Rendering

You can specify custom HTML types and provide custom renderers for specialized field display:

```elixir
auix_resource_metadata :product do
  context MyApp.Inventory
  schema MyApp.Inventory.Product
  field :status, html_type: :select,
    data: %{select: %{opts: [Active: "active", Inactive: "inactive", Archived: "archived"]}}
  field :avatar, html_type: :image, renderer: &MyAppWeb.Helpers.render_avatar/1
end
```

The `html_type` option overrides the automatic HTML type inference. The `renderer` option allows providing a custom function or component for rendering the field.

A renderer of the form or the show view can send an event to the component with `phx-target={@auix._myself}`; see
[Targeting the Component](liveview.md#targeting-the-component).

### Per-layout renderers

`renderer` applies to the **form (edit)** and **show** layouts. To render a field differently
depending on the layout, use the per-layout renderer options — each is a 1-arity function (or
component) that receives the render assigns and returns a `Phoenix.LiveView.Rendered.t()`:

```elixir
auix_resource_metadata :product do
  context MyApp.Inventory
  schema MyApp.Inventory.Product
  field :status,
    index_renderer: &MyAppWeb.Helpers.status_badge/1,
    edit_renderer: &MyAppWeb.Helpers.status_select/1,
    show_renderer: &MyAppWeb.Helpers.status_label/1
end
```

Precedence:

- **index** layout — uses `index_renderer` if set, otherwise the default rendering. The index
  layout never falls back to `renderer`.
- **form (edit)** layout — uses `edit_renderer` if set, otherwise `renderer`, otherwise the
  default rendering.
- **show** layout — uses `show_renderer` if set, otherwise `renderer`, otherwise the default
  rendering.

The render assigns available to a renderer include `@field` (the `Aurora.Uix.Field` struct) and
`@auix` (the render context, e.g. `@auix.entity` in show/index and `@auix.form` in the form
layout); index renderers also receive the row `@entity`.

A renderer set here applies wherever its layout renders the field. To override rendering for a
single layout at the layout-definition site instead, use
[field-level options in the layout DSL](layouts.md#field-level-options). For the full catalog of
rendering customization points, see
[Customizing & Extending Aurora UIX](../customization/customization.md#3-custom-field-rendering).

## Associations

Aurora UIX handles **many_to_one** (`belongs_to`), **one_to_many** (`has_many`), **one_to_one** (`has_one`) and **many_to_many** associations, and **embeds_one** and **embeds_many** fields. You can configure their behavior in the resource metadata.

### Automatic Association Detection

Association detection behavior depends on the backend implementation. The mapping described below corresponds to the current implemented backends (Context-based and Ash Framework).

Associations are automatically detected from your schema and converted to association fields:

- `belongs_to` → `many_to_one_association` type
- `has_many` → `one_to_many_association` type
- `has_one` → `one_to_one_association` type
- `many_to_many` → `many_to_many_association` type
- `embeds_one` → `embeds_one` type
- `embeds_many` → `embeds_many` type

Custom backend implementations may provide different association detection mechanisms while maintaining compatibility with Aurora UIX's rendering system.

### Many-to-One (belongs_to)

When the module declares a resource for the related schema, the foreign key field of a `belongs_to`
association renders as a dropdown. Without `option_label`, each option shows the related primary
key.

The `option_label` option controls the label of each option. Set it on the foreign key field. It
supports three patterns:

- **As an atom (field name)** - Shows a single field of the related entity:
  ```elixir
  field :category_id, option_label: :name
  ```

- **As a function (arity 1)** - Receives the related entity and returns the label:
  ```elixir
  field :category_id, option_label: &MyApp.Category.label/1
  ```

- **As a function (arity 2)** - Receives the rendering assigns and the entity:
  ```elixir
  # In your Category module:
  def label(%{auix: %{layout_type: :index}}, category), do: category.code
  def label(_assigns, category), do: "#{category.code} - #{category.name}"
  ```
  ```elixir
  field :category_id, option_label: &MyApp.Category.label/2
  ```

### Query Options for Many-to-One

`query_opts` shapes the query behind the dropdown, with or without `option_label`:

- `:order_by` - Controls the ordering of options in the dropdown
- `:where` - Filters the options to display

**Examples:**

```elixir
# Renders a selector displaying names ordered ascending
auix_resource_metadata :product do
  context MyApp.Inventory
  schema MyApp.Inventory.Product
  field :category_id, option_label: :name, query_opts: [order_by: :name]
end
```

```elixir
# Renders a selector with filtered options ordered descending by reference
auix_resource_metadata :product do
  context MyApp.Inventory
  schema MyApp.Inventory.Product
  field :category_id, option_label: :name,
    query_opts: [order_by: [desc: :reference], where: [{:name, :between, "A", "Z"}]]
end
```

### One-to-Many (has_many)

A **one-to-many** (`has_many`) field renders as a list with actions for adding, editing and
deleting items. The list has no filters or sortable headers of its own.

To order or filter its rows, set `query_opts` on the field in the resource metadata, or these
options on the field in the layout:

- `:order_by` - Order of the rows, in Ecto's `order_by` syntax
- `:where` - Filter of the rows, in the syntax described under
  [QueryBuilder for Advanced Filtering](layouts.md#querybuilder-for-advanced-filtering)

```elixir
auix_resource_metadata :product do
  context Inventory
  schema Product
  field :product_transactions, query_opts: [order_by: [asc: :inserted_at], where: [{:quantity, :gt, 0}]]
end

auix_create_ui do
  edit_layout :product do
    stacked do
      field :reference
      field :product_transactions, order_by: [desc: :quantity]
    end
  end
end
```

An option set in the layout takes precedence over the same option in `query_opts`; the other one
still applies. Above, the rows keep the `where` of the metadata and follow the `order_by` of the
layout.

## Related guides

- [Customizing & Extending Aurora UIX](../customization/customization.md) — the central customization hub, including a [field options reference table](../customization/customization.md#6-field-and-resource-options-reference)
- [Layout System](layouts.md) — arrange the configured fields in index, form, and show views
- [Ash Integration](ash_integration.md) — Ash-specific metadata options and action resolution
- [Advanced Usage](../advanced/advanced_usage.md) — separating metadata from UI modules




