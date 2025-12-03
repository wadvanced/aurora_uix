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

## CSS Configuration

Aurora UIX can render UI using custom templates and/or custom themes.
So, we decided to used our own set of css rules.

A `basic` template along with the `light` and `dark` themes are included as default 
in the package distribution.

Css stylesheet resolution needs some configuration for it to work.

### Configure Stylesheet Service
Add auix's stylesheet path to a :api pipeline in the `router.ex` module.
Here is a code snippet example for setting the path route.

```elixir
  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/auix/assets/", Aurora.Uix do
    pipe_through(:api)
    get("/css/stylesheet.css", Templates.CssServer, :generate)
  end
```

[!NOTE] You can set another path for the stylesheet, 
if you do so, reflect that change in the corresponding `link` tag declaration that
must be included in the main layout (usually root.html.heex or app.html.heex).

### Include Stylesheet in Main Layout
In your main layout (root.html.heex, app.html.heex) add a link to `/auix/assets/css/stylesheet.css`.
The head might look like the following:
```html
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="csrf-token" content={get_csrf_token()} />
    <.live_title default="Aurora.Uix" suffix=" · Phoenix Framework">
      {assigns[:page_title]}
    </.live_title>
    <link phx-track-static rel="stylesheet" href={~p"/assets/css/app.css"} />
    <!-- Add this vvvvvvvvv line -->
    <link rel="stylesheet" href={"/auix/assets/css/stylesheet.css"} />
    <!-- ^^^^^^^^^^^^^^^^^^^ -->
    <script defer phx-track-static type="text/javascript" src={~p"/assets/js/app.js"}>
    <!-- .... other tags .... -->
  </head>
  ```
> [!NOTE] Stylesheet loaded thru url are bound to be cached by browsers, if you experience that changes to rules does not apply upon reloading, replace the header link tag with the following:
> ```html
> <link rel="stylesheet" href={"/auix/assets/css/stylesheet.css?gen=#{System.os_time()}"} />
> ```

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
scope "/inventory", Aurora.UixWeb.Guides do
  pipe_through(:browser)
  live "/products", Overview.Product.Index
  live "/products/new", Overview.Product.Index, :new
  live "/products/:id/edit", Overview.Product.Index, :edit
  live "/products/:id", Overview.Product.Show, :show
  live "/products/:id/show/edit", Overview.Product.Show, :edit
end
```

[!NOTE] You can simplify route registration by using the `Aurora.Uix.RouteHelper` macro. 
It automatically generates these routes for you.

```elixir
import Aurora.Uix.RouteHelper

scope "/inventory", Aurora.UixWeb.Guides do
  pipe_through(:browser)
  auix_live_resources("/products", Overview.Product)
end
```


4. **Run Your App**

Start your Phoenix server and visit `/products` to see your UI.

For more details on field options and advanced layouts, see the [Resource Metadata guide](../../guides/core/resource_metadata.md).
