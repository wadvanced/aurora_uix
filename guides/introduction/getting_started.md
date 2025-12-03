# Getting Started

Welcome to **Aurora UIX**! This guide helps you add Aurora UIX to your Phoenix project and build your first CRUD UI with minimal code.

Aurora UIX is a low-code framework for building dynamic, metadata-driven UIs in Phoenix LiveView applications. It lets you define schema metadata once and automatically generate complete CRUD interfaces.

## Alpha Version Notice

This library is currently in alpha stage. Several functionalities are still being implemented, and existing APIs are subject to improvement. We recommend monitoring the [CHANGELOG.md](../CHANGELOG.md) for breaking changes between releases.

## Installation

Add `aurora_uix` to your `mix.exs` dependencies. Make sure your Phoenix project is using Phoenix 1.7+ (which includes LiveView support):

```elixir
def deps do
  [
    {:aurora_uix, "~> 0.1.0-alpha.1"}
  ]
end
```

Then fetch the dependencies:

```shell
mix deps.get
```

## CSS Configuration

Aurora UIX renders UI with pre-built CSS themes. A `basic` template with `light` and `dark` themes are included by default.

For styling to work, you need to configure the CSS stylesheet service in your router and add the stylesheet link to your layout.

### Step 1: Add Stylesheet Route

In your `router.ex`, add a route to serve the dynamically generated CSS:

```elixir
  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/auix/assets/", Aurora.Uix do
    pipe_through(:api)
    get("/css/stylesheet.css", Templates.CssServer, :generate)
  end
```

The path can be customized, but you'll need to update the stylesheet link in your layout accordingly.

### Step 2: Include Stylesheet Link in Layout

In your main layout file (typically `root.html.heex` or `app.html.heex`), add a link to the generated stylesheet in the `<head>` section:

```html
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <meta name="csrf-token" content={get_csrf_token()} />
  <.live_title default="Aurora.Uix" suffix=" · Phoenix Framework">
    {assigns[:page_title]}
  </.live_title>
  <link phx-track-static rel="stylesheet" href={~p"/assets/css/app.css"} />
  <!-- Aurora UIX Stylesheet -->
  <link rel="stylesheet" href={"/auix/assets/css/stylesheet.css"} />
  <script defer phx-track-static type="text/javascript" src={~p"/assets/js/app.js"}>
  </script>
</head>
```

> #### Stylesheet Caching {: .info}
> Browsers may cache stylesheets aggressively. If style changes aren't appearing after reloading, update the link to bust the cache:
> ```html
> <link rel="stylesheet" href={"/auix/assets/css/stylesheet.css?v=#{System.os_time()}"} />
> ```

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
  live "/products/:id", Overview.Product.Show, :show
  live "/products/:id/show/edit", Overview.Product.Show, :edit
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
