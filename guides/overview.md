# Aurora UIX

Aurora UIX is a low-code UI framework for the Elixir Phoenix ecosystem, designed to rapidly generate CRUD user interfaces with minimal boilerplate. It leverages resource metadata, a declarative layout DSL, and compile-time code generation to produce maintainable, extensible, and consistent LiveView-based UIs.

## Core Concepts

- **Resource Metadata**: Define schema-based resource configurations using `auix_resource_metadata/3`, specifying field-level UI options, associations, and validation rules.
- **Layout DSL**: Compose layouts for forms, lists, and detail views using macros like `edit_layout`, `show_layout`, `index_columns`, `group`, `inline`, `stacked`, and `sections`.
- **Compile-Time UI Generation**: Aurora UIX generates LiveView modules and HEEx templates at compile time, ensuring fast runtime performance and type safety.
- **Extensible Templates**: The system supports pluggable template engines and customizable rendering logic, allowing for advanced UI customization and integration with custom components.

## Features

- Declarative resource and field configuration
- Automatic CRUD UI generation (index, form, show)
- Flexible, composable layouts with grouping and tabbed sections
- Association handling (one-to-many, many-to-one)
- Compile-time generation for minimal runtime overhead
- Extensible template and component system
- Integrated i18n support via configurable Gettext backend

## Example Usage

```elixir
defmodule MyAppWeb.ProductViews do
  use Aurora.Uix.Layout.CreateUI

    auix_resource_metadata :product_location, context: Inventory, schema: ProductLocation

    auix_resource_metadata :product_transaction, context: Inventory, schema: ProductTransaction

    auix_resource_metadata(:product, context: Inventory, schema: Product) do
      field(:product_location_id, option_label: :name)
    end

    auix_create_ui(link_prefix: "basic-demo-") do
      index_columns :product, [:reference, :name, :description, :quantity_at_hand]
      index_columns :product_transaction, [:type, :quantity, :cost]

      edit_layout :product_location do
        inline([:reference, :name, :type])
      end

      show_layout :product do
        stacked do
          inline [:reference, :name, :description]
          inline [:description]
          inline [:product_location]
        end
      end

      edit_layout :product do
        stacked do
          inline [:reference]
          sections do
            section "Description" do
              stacked [:name, :description]
            end
            section "Quantities" do
              stacked [:quantity_initial, :quantity_entries, :quantities_exits]
            end
          end
          inline [:product_transactions]
        end
      end
    end
  end
end
```
Will produce the whole UI interface for **C**reating, **R**eading (showing), **U**pdating (editing) and **D**eleting along with validation, association handling. The following images shows part of the automatically generated UI:

#### Index listing
<img src="./assets/screenshots/index.png" width="600"/>

#### Record showing
<img src="./assets/screenshots/show.png" width="600"/>

#### Record editing
<img src="./assets/screenshots/edit.png" width="600"/>

## When to Use Aurora UIX

- Rapid prototyping of Phoenix CRUD interfaces
- Projects that benefit from convention-over-configuration and consistent UI patterns
- Teams seeking to minimize repetitive UI code and focus on business logic

## Extending Aurora UIX

- Implement custom templates or override rendering logic
- Add custom field renderers or extend the layout DSL
- Integrate with your own Phoenix components and styles

See the guides and documentation for more details on configuration, customization, and advanced usage.
