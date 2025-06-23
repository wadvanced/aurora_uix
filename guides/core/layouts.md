# Layout System

Aurora UIX provides a flexible layout DSL for forms, lists, and detail views.

The layout system is designed to give you full control over how your UI is structured. By default, Aurora UIX generates layouts automatically, so you get a functional interface with no extra code. When you need more control, you can define layouts explicitly using the provided DSL. This allows you to create anything from simple arrangements to complex, visually organized forms and views, all with concise and readable code.

## Layout Types and Their Purpose

Each layout type in Aurora UIX determines how your resource metadata (the fields and associations you describe) is presented in the UI:

- **Index Layout**: Defines which fields from your resource metadata are shown in the list (table) view. You use `index_columns` to select and order fields for the index page.
- **Form Layout**: Controls the arrangement of fields when creating or editing a resource. The form layout uses your resource metadata to generate input fields, respecting options like `placeholder`, `required`, and custom renderers.
- **Show Layout**: Specifies how fields are displayed in the read-only detail view. It uses the same resource metadata, but renders fields as static values.

## Sub-Layouts: Containers for Structure

Sub-layouts are general-purpose containers that let you organize fields and other sub-layouts. This means you can nest fields and other sub-layouts as needed to achieve your desired UI structure.

The main sub-layouts are:

- **inline**: Arranges its contents horizontally in a row.
- **stacked**: Arranges its contents vertically in a column. This is the default sub-layout when no layout is defined.
- **group**: Visually groups related contents under a title and a frame.
- **sections**: Creates a tabbed container. Each `sections` block contains one or more `section` sub-layouts.
- **section**: Represents a single tab inside a `sections` container. Each `section` is itself a container that holds sub-layouts.

Each layout and sub-layout references your resource metadata, so any field-level options (like `readonly`, `renderer`, or `option_label`) are respected wherever the field appears.

## Layout Examples

### 1. No-Code: Default Layout

If you do not define any layout, Aurora UIX generates a default layout for index, show, and edit views based on your resource metadata:

```elixir
auix_create_ui do
  # No layout specified
end
```
<img src="./images/layouts/default-1.png" width="600"/>
<img src="./images/layouts/default-2.png" width="400"/>

### 2. Inline Layout

```elixir
edit_layout :product do
  inline [:reference, :name, :description]
end
```
<img src="./images/layouts/inline-1.png" width="400"/>

### 3. Stacked Layout

```elixir
edit_layout :product do
  stacked [:reference, :name, :description]
end
```
<img src="./images/layouts/stacked-1.png" width="400"/>

### 4. Group Layout

```elixir
edit_layout :product do
  group "Product Info", do: stacked [:reference, :name, :description]
end
```
<img src="./images/layouts/group-1.png" width="600"/>

### 5. Sections Layout

```elixir
edit_layout :product do
  sections do
    section "Main" do
      inline [:reference, :name]
    end
    section "Details" do
      stacked [:description]
    end
  end
end
```
<img src="./images/layouts/sections-1.png" width="600"/>
<img src="./images/layouts/sections-2.png" width="600"/>

### 6. Nested Layout (Combining All Sub-Layouts)

```elixir
edit_layout :product do
  stacked do
    group "Identification" do
      inline [:reference, :name]
    end
    sections do
      section "Description" do
        stacked [:description]
      end
      section "Quantities" do
        stacked [:quantity_initial, :quantity_entries, :quantity_exits]
      end
    end
    inline [:product_transactions]
  end
end
```
<img src="./images/layouts/nested-1.png" width="600"/>

## Default Layouts

If you omit a layout, Aurora UIX generates a default layout for index, show and edit.
s