# Getting Started

Welcome to **Aurora UIX**! This guide helps you add Aurora UIX to your Phoenix project and build your first CRUD UI with minimal code.

## Installation

Add `aurora_uix` to your `mix.exs` dependencies:

```elixir
def deps do
  [
    {:aurora_uix, "~> 0.1.0"}
  ]
end
```

Fetch dependencies:

```shell
mix deps.get
```

## Tailwind Configuration

### Versions 4.x
After following the [installation](https://tailwindcss.com/docs/installation/framework-guides/phoenix) guide for phoenix, 
open assets/css/app.css and look for the following lines.

```css
@import "tailwindcss" source(none);
@source "../css";
@source "../js";
@source "../../lib/your_app_web";
...
```

Add this source reference after yours app reference.
```css
@source "../../deps/aurora_uix/lib";
```

You should have something like the following:
```css
@import "tailwindcss" source(none);
@source "../css";
@source "../js";
@source "../../lib/your_app_web";
@source "../../deps/aurora_uix/lib";
```

Now you can build your tailwind classes.

### Versions 3.x
Add Aurora UIX to your `tailwind.config.js` content paths to ensure all styles are included ('aurora_demo' used as an application example):

```js
module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/aurora_demo_web.ex",
    "../lib/aurora_demo_web/**/*.*ex",
    "../deps/aurora_uix/**/*.ex"
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
```

## Basic Usage

1. **Define Resource Metadata**

Describe your schema and UI options using the DSL:

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

2. **Generate UI Layout**

Use the layout DSL to define your UI (or rely on sensible defaults):

```elixir
auix_create_ui do
  index_columns :product, [:name, :price]
  edit_layout :product do
    inline [:name, :price, :description]
  end
end
```

3. **Add to Router**

Add the generated LiveView modules to your router:

```elixir
live "/products", MyAppWeb.ProductViews.Product.Index
live "/products/new", MyAppWeb.ProductViews.Product.Index, :new
live "/products/:id/edit", MyAppWeb.ProductViews.Product.Index, :edit

live "/products/:id", MyAppWeb.ProductViews.Product.Show, :show
live "/products/:id/show/edit", MyAppWeb.ProductViews.Product.Show, :edit

```

4. **Run Your App**

Start your Phoenix server and visit `/products` to see your UI.

For more details on field options and advanced layouts, see the [Resource Metadata guide](../../guides/core/resource_metadata.md).
