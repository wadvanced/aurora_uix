# Getting Started

Welcome to **Aurora UIX**! This guide helps you add Aurora UIX to your Phoenix project and build your first CRUD UI with minimal code.

Aurora UIX is a low-code framework for building dynamic, metadata-driven UIs in Phoenix LiveView applications. It lets you define schema metadata once and automatically generate complete CRUD interfaces.

> #### New to Elixir or Phoenix? {: .tip}
> This guide assumes you already have a Phoenix project. If you're starting from
> scratch, follow the [Build Your First App](../tutorial/build_your_first_app.md)
> tutorial first — it installs the toolchain and builds a complete app from
> nothing, then sends you back here for the details.

## Installation

Add `aurora_uix` to your `mix.exs` dependencies. Make sure your Phoenix project is using Phoenix 1.7+ (which includes LiveView support):

```elixir
def deps do
  [
    {:aurora_uix, "~> 0.1.4"}
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

This generates three files under `assets/css/`:

- `auix-variables.css` — `:root` declarations for all `--auix-*` custom properties (sizes, colors, shadows).
- `auix-rules.css` — the `.auix-*` component rules that consume those variables.
- `auix-stylesheet.css` — back-compat shim that re-imports the two files above.

### Step 2: Import Stylesheets in app.css

In your `assets/css/app.css`, import the variables first, optionally override individual `--auix-*` vars (directly or via a bridge file — see below), then import the rules **last**:

```css
/* Your custom styles and other imports go here */

@import "auix-variables.css";       /* Aurora UIX defaults */
:root { /* optional: override --auix-* vars here */ }
@import "auix-rules.css";           /* must be last */
```

Hosts on the previous single-file install keep working — `@import "auix-stylesheet.css"` is still generated and now just re-imports the two halves above.

> #### Why Rules Last? {: .warning}
> `auix-rules.css` must be imported as the **last** Aurora UIX line in `app.css` so its component selectors have the highest specificity and any overrides you placed between the two imports take effect.

The stylesheets are bundled with your application CSS and served alongside your other assets. Your main layout file (`root.html.heex` or `app.html.heex`) already includes the standard asset link:

```html
<link phx-track-static rel="stylesheet" href={~p"/assets/css/app.css"} />
```

> #### Regenerating After Theme Changes {: .info}
> If you change your Aurora UIX theme configuration, re-run `mix auix.gen.stylesheet` to update the generated stylesheets.
>
> **Note**: This command is also used when creating custom themes. See the [Creating Custom Registered Themes](../customization/theming.md) guide for details on building your own themes.

### Step 3 (optional): Inherit the host's daisyUI theme

If your Phoenix app uses Tailwind v4 + daisyUI, Aurora UIX can follow the host theme automatically. The first time you run `mix auix.gen.stylesheet` it also copies a bridge file — `assets/css/auix-bridge-daisyui.css` — a small mapping that connects daisyUI tokens (`--color-primary`, `--color-base-100`, `--radius-field`, …) to `--auix-*` variables. Import it between the variables and the rules:

```css
@import "tailwindcss";
@plugin "daisyui";

@import "auix-variables.css";       /* Aurora UIX defaults */
@import "auix-bridge-daisyui.css";  /* inherit daisyUI theme */
:root { /* optional host overrides */ }
@import "auix-rules.css";           /* must be last */
```

Switching the daisyUI theme (or toggling dark mode) then automatically restyles every Aurora UIX component with no further mix tasks. The bridge file is yours to edit — subsequent runs of `mix auix.gen.stylesheet` leave it untouched. Run with `--force` to refresh it from the library version:

```shell
mix auix.gen.stylesheet --force
```

If you use a design system other than daisyUI, see the [Writing a Style Bridge](../customization/writing_a_style_bridge.md) guide to create your own mapping.

## Icons Configuration

Aurora UIX uses **Heroicons** for all UI icons. Heroicons provides multiple icon sets and sizes (outline, solid, mini, and micro variants).

### If You're Already Using Heroicons

If your host application is already using Heroicons, add this single source line to your `app.css` so Tailwind includes only the icon classes Aurora UIX needs — without scanning the entire dependency tree:

```css
@source "../../deps/aurora_uix/priv/static/classes.js";
```

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

## JavaScript Setup

Aurora UIX ships client-side hooks and event listeners in `assets/js/hooks.js`. Host applications
must import this file in their own `assets/js/app.js` so the browser can receive events pushed by
the server (e.g. file downloads from upload fields) and activate hooks (e.g. the theme switcher on
index pages).

Add the import and spread the hooks into your `LiveSocket` configuration:

```js
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {Hooks as auroraHooks} from "../../deps/aurora_uix/assets/js/hooks.js"

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  params: {_csrf_token: csrfToken},
  hooks: {...auroraHooks},   // spread alongside your own app hooks if any
})
```

Rebuild your assets after adding the import:

```shell
mix assets.build
```

> #### What does this enable? {: .info}
> - **`AuixThemeName` hook** — syncs the active theme on index pages.
> - **`phx:auix_download` listener** — performs browser file downloads for upload fields configured
>   with a `:download` callback. Without this import, clicking the Download button on a show or edit
>   page will silently do nothing.

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

> **Using Ash with policies?** If your resource is protected by
> `Ash.Policy.Authorizer`, add `ash_actor_assign: :current_user` to thread the
> current user as the Ash actor on every generated CRUD call. See
> [Ash Integration → Authorization & policies](../core/ash_integration.md#authorization--policies).

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
- Show: `GET /products/:id/show`
- Edit from Show: `GET /products/:id/show-edit`
- Edit: `GET /products/:id/edit`

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
- **[Customizing & Extending Aurora UIX](../customization/customization.md)** - Make the generated UI look and behave like your app — styling, theming, component overrides, custom actions
- **[Advanced Usage](../advanced/advanced_usage.md)** - Custom templates and backends

### Common Tasks

- **Add field validation** - Configure `required`, `readonly`, and custom validation in resource metadata
- **Handle associations** - Configure many-to-one selects and one-to-many lists
- **Customize styling** - Create custom themes to match your design system
- **Add business logic** - Connect Aurora UIX with your context functions for CRUD operations

### Troubleshooting

If you encounter issues, check the [Troubleshooting Guide](../advanced/troubleshooting.md).
