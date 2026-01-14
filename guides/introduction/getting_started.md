# Getting Started

Welcome to **Aurora UIX**! This guide helps you add Aurora UIX to your Phoenix project and build your first CRUD UI with minimal code.

Aurora UIX is a low-code framework for building dynamic, metadata-driven UIs in Phoenix LiveView applications. It lets you define schema metadata once and automatically generate complete CRUD interfaces.

## Installation

Add `aurora_uix` to your `mix.exs` dependencies. Make sure your Phoenix project is using Phoenix 1.7+ (which includes LiveView support):

```elixir
def deps do
  [
    {:aurora_uix, "~> 0.1.2"}
  ]
end
```

Then fetch the dependencies:

```shell
mix deps.get
```

## CSS Configuration

Aurora UIX renders UI with pre-built CSS themes. A `basic` template with `light` and `dark` themes are included by default.

To enable Aurora UIX styling, generate the stylesheet and import it in your application's CSS:

### Step 1: Generate the Stylesheet

Run the stylesheet generator task:

```shell
mix auix.gen.stylesheet
```

This generates `assets/css/auix-stylesheet.css` with your configured theme and styling.

### Step 2: Import Stylesheet in app.css

In your `assets/css/app.css`, add an import statement **at the end** (as the last line):

```css
/* Your custom styles and other imports go here */

/* Aurora UIX stylesheet must be imported last to avoid conflicts */
@import "auix-stylesheet.css";
```

> #### Why Last? {: .warning}
> The Aurora UIX stylesheet must be imported as the **last line** in `app.css` to ensure its styles have the highest specificity and properly override any conflicting styles from other CSS files or frameworks.

That's it! The stylesheet will be bundled with your application CSS and automatically served alongside your other assets. Your main layout file (`root.html.heex` or `app.html.heex`) already includes the standard asset link:

```html
<link phx-track-static rel="stylesheet" href={~p"/assets/css/app.css"} />
```

> #### Regenerating After Theme Changes {: .info}
> If you change your Aurora UIX theme configuration, re-run `mix auix.gen.stylesheet` to update the generated stylesheet.
>
> **Note**: This command is also used when creating custom themes. See [Creating Custom Registered Themes](../advanced/advanced_usage.html#creating-custom-registered-themes) in the Advanced Guide for details on building your own themes.

## Icons Configuration

Aurora UIX uses **Heroicons** for all UI icons. Heroicons provides multiple icon sets and sizes (outline, solid, mini, and micro variants).

### If You're Already Using Heroicons

If your host application is already using Heroicons, **no additional setup is needed**. Aurora UIX will use your existing Heroicons installation.

### If You're Not Using Heroicons

Generate the icon CSS classes used by Aurora UIX:

```shell
mix auix.gen.icons
```

This generates `assets/css/auix-icons.css` containing all Heroicons as CSS classes (`.hero-{icon-name}`, `.hero-{icon-name}-solid`, `.hero-{icon-name}-mini`, `.hero-{icon-name}-micro`).

### Import Icons in app.css

In your `assets/css/app.css`, add an import statement at the top:

```css
@import "auix-icons.css";
```

> #### Using Custom Icons {: .info}
> If you need to add your own icon classes or modify the generated ones, edit `assets/css/auix-icons.css` directly. Re-running `mix auix.gen.icons` will overwrite this file, so keep a backup of any custom changes.

## Basic Usage

Aurora UIX works in three main steps:

### 1. Define Resource Metadata

Resource metadata describes the UI characteristics of fields in your Ecto schema. Use the `auix_resource_metadata/3` macro to configure how each field should be rendered:

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

This tells Aurora UIX:
- How to label and validate fields
- What input types to render (text, number, checkbox, etc.)
- Which fields are required, readonly, or hidden

For detailed configuration options, see the [Resource Metadata Guide](../core/resource_metadata.md).

### 2. Generate UI Layout

Use the layout DSL to define which fields appear in your index (list), show, and form views. You can use sensible defaults or customize the layout:

```elixir
  auix_create_ui do
    index_columns :product, [:name, :price]
    edit_layout :product do
      inline [:name, :price, :description]
    end
  end
```

For more layout options, see the [Layouts Guide](../core/layouts.md).

### 3. Add Routes to Router

Add the generated LiveView modules to your router. The standard pattern includes index, show, new, and edit views:

```elixir
scope "/inventory" do
  pipe_through(:browser)
  live "/products", Overview.Product.Index
  live "/products/new", Overview.Product.Index, :new
  live "/products/:id/edit", Overview.Product.Index, :edit
  live "/products/:id/show", Overview.Product.Index, :show
  live "/products/:id/show-edit", Overview.Product.Index, :show_edit
end
```

**Alternatively, use the route helper for shorter syntax:**

```elixir
import Aurora.Uix.RouteHelper

scope "/inventory", Aurora.UixWeb.Guides do
  pipe_through(:browser)
  auix_live_resources("/products", Overview.Product)
end
```

This automatically generates all the routes above with the standard CRUD pattern:
- Index: `GET /products`
- New: `GET /products/new`
- Create: `POST /products` (handled by LiveView)
- Show: `GET /products/:id`
- Edit: `GET /products/:id/edit`
- Update: `PATCH /products/:id` (handled by LiveView)

You can also selectively generate routes using `:only` or `:except` options:

```elixir
# Generate only index and show routes
auix_live_resources("/products", Overview.Product, only: [:index, :show])

# Generate all routes except new and edit (read-only mode)
auix_live_resources("/products", Overview.Product, except: [:new, :edit])
```

For more details on routing, see the [LiveView Integration Guide](../core/liveview.md).

### Run Your App

Start your Phoenix server and navigate to the defined paths to see your complete CRUD UI:

```shell
mix phx.server
```

Visit `http://localhost:4000/inventory/products` to see your generated interface with list, detail, create, and edit views.

## Next Steps

Now that you have Aurora UIX running, here are some recommended next steps:

### Learn More

- **[Resource Metadata Guide](../core/resource_metadata.md)** - Deep dive into field configuration, associations, and custom renderers
- **[Layouts Guide](../core/layouts.md)** - Master the layout DSL for customizing UI composition
- **[LiveView Integration Guide](../core/liveview.md)** - Integrate Aurora UIX with your LiveView event handlers
- **[Advanced Usage](../advanced/advanced_usage.md)** - Custom components, themes, and extending Aurora UIX

### Common Tasks

- **Add field validation** - Configure `required`, `readonly`, and custom validation in resource metadata
- **Handle associations** - Configure many-to-one selects and one-to-many lists
- **Customize styling** - Create custom themes to match your design system
- **Add business logic** - Connect Aurora UIX with your context functions for CRUD operations

### Troubleshooting

If you encounter issues, check the [Troubleshooting Guide](../advanced/troubleshooting.md).
