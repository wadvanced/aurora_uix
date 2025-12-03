# Getting Started

Welcome to **Aurora UIX**! This guide helps you add Aurora UIX to your Phoenix project and build your first CRUD UI with minimal code.

## A Note About Alpha Version
This library is still in alpha stage. 

There are several functionalities left to be implemented, and existing ones bound to be improved.
Therefore, expect important changes in future releases.

## Installation

Add `aurora_uix` to your `mix.exs` dependencies:

```elixir
def deps do
  [
    {:aurora_uix, "~> 0.1.0-alpha.1"}
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

> #### Note {: .info}
> You can set another path for the stylesheet, 
> if you do so, reflect that change in the corresponding `link` tag declaration that
> must be included in the main layout (usually root.html.heex or app.html.heex).

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
> #### Note {: .info}
> Browsers cache stylesheet, if you experience that changes to rules are not applied, even after reloading, replace the header link tag with the following code snippet:
> ```html
> <link rel="stylesheet" href={"/auix/assets/css/stylesheet.css?gen=#{System.os_time()}"} />
> ```

## Basic Usage

1. **Define Resource Metadata**

The resource metadata allows to define the UI characteristics of each of the fields in the schema.

In the following example, the use of macro `auix_resource_metadata` aids into defining fields' properties:

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

You can learn more about the resource_metadata syntax in the [`Resource Metadata`](../../guides/core/resource_metadata.md)i guide.

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

3. **Add Paths to Router**

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

> #### Note {: .info}
> CRUD paths can be simplified by the `Aurora.Uix.RouteHelper.auix_live_resources/2` macro. 
> It automatically generates the same previously shown paths.

```elixir
import Aurora.Uix.RouteHelper

scope "/inventory", Aurora.UixWeb.Guides do
  pipe_through(:browser)
  auix_live_resources("/products", Overview.Product)
end
```


4. **Run Your App**

Start your Phoenix server and visit any of the defined paths to access a complete and functional CRUD UI.

To learn more, get acquainted with the [`Resource Metadata`](../../guides/core/resource_metadata.md) guide and the 
[`Layout System`](../../guides/core/layouts.md) guide.
