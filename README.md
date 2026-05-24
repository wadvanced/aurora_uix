<p align="center">
  <img src="./guides/images/aurora_uix-logo.svg" height="200" />
</p>

[![CI](https://github.com/wadvanced/aurora_uix/actions/workflows/ci.yml/badge.svg)](https://github.com/wadvanced/aurora_uix/actions/workflows/ci.yml)
[![Hex.pm](https://img.shields.io/hexpm/v/aurora_uix.svg)](https://hex.pm/packages/aurora_uix)
[![Downloads](https://img.shields.io/hexpm/dt/aurora_uix.svg)](https://hex.pm/packages/aurora_uix)
[![Documentation](https://img.shields.io/badge/documentation-gray)](https://hexdocs.pm/aurora_uix)
[![Last Commit](https://img.shields.io/github/last-commit/wadvanced/aurora_uix.svg)](https://github.com/wadvanced/aurora_uix/commits/main)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-%23FE5196?logo=conventionalcommits&logoColor=white)](https://conventionalcommits.org)

# Aurora UIX

**Declarative, compile-time CRUD UI generation for Elixir's Phoenix LiveView.** Build feature-rich, responsive interfaces with minimal code using metadata-driven configuration and a powerful layout DSL.

---
## 📖 Overview

Aurora UIX is a metadata-driven UI framework for Elixir's Phoenix LiveView that lets you rapidly generate complete CRUD interfaces from your Ecto schemas. Instead of writing repetitive form and list code, define your resource once and get a fully functional, responsive UI with built-in validation, association handling, and real-time updates.

**Why Aurora UIX?**
- **Rapid Development** — Build CRUD interfaces in minutes, not days. Define resource metadata once, get complete index, show, and edit views.
- **Type-Safe Code Generation** — All UI code is generated at compile-time, not runtime. Full type safety with zero overhead.
- **Extensible by Design** — Customize every layer: field renderers, layouts, templates, themes, and LiveView event handlers.
- **Production-Ready Features** — Built-in pagination, validation, error handling, i18n, responsive design, and real-time updates via LiveView.

**Key Features:**
- **Multiple Backend Support** — Works seamlessly with Ecto schemas and Ash Framework resources through automatic adapter detection.
- **Policy-Aware CRUD** — For Ash resources protected by `Ash.Policy.Authorizer`, set [`ash_actor_assign:`](./guides/core/ash_integration.md#authorization--policies) and Aurora UIX threads the current actor through every generated call.
- **Declarative Resource Metadata** — Define fields, validation, labels, and associations in a single, maintainable place.
- **Flexible Layout DSL** — Compose complex UIs using `inline`, `stacked`, and `section` layout primitives.
- **Complete CRUD Generation** — Automatic index, show, and edit views with pagination, filtering, and sorting.
- **Association Support** — First-class support for `belongs_to`, `has_many`, `embeds_one`, and `embeds_many`.
- **Responsive Design** — Mobile-first layouts that work seamlessly on all devices.
- **i18n Support** — Built-in internationalization via configurable Gettext backend.
- **Customizable Themes** — Besides the included themes, you can create your own or override partially the existing ones.

**Technology Stack:**
- Elixir `1.17+`
- Phoenix `1.8+`
- Phoenix LiveView `1.1+`
- Ecto `3.13+`

---
## ⚡ Quick Example

See Aurora UIX in action. In just a few lines of code, generate a complete, responsive product management interface:

```elixir
defmodule MyAppWeb.Products do
  use Aurora.Uix
  alias MyApp.Inventory.Product

  # 1. Define resource metadata (once)
  auix_resource_metadata :product, context: MyApp.Inventory, schema: Product do
    field :name, placeholder: "Product name", required: true
    field :price, precision: 12, scale: 2
    field :stock, required: true
  end

  # 2. Define layouts for each view
  auix_create_ui do
    # Index with pagination
    index_columns :product, [:name, :price, :stock],
      pagination_items_per_page: 20

    # Organized edit form
    edit_layout :product do
      stacked do
        inline [:name]
        sections do
          section "Pricing" do
            stacked [:price]
          end
          section "Inventory" do
            stacked [:stock]
          end
        end
      end
    end

    # Detailed show view
    show_layout :product do
      stacked do
        inline [:name, :price, :stock]
      end
    end
  end
end
```

**Result:** Complete, responsive CRUD interface with:
- ✅ Paginated list view with sorting and filtering
- ✅ Organized multi-section edit form
- ✅ Detailed product view
- ✅ Automatic validation and error handling
- ✅ Real-time updates via Phoenix LiveView
- ✅ Mobile-responsive design
- ✅ Theme support

---
## 🚀 Getting Started

### Prerequisites

Ensure you have the following installed:
- [Elixir](https://elixir-lang.org/install.html) 1.17+
- [Erlang](https://www.erlang.org/downloads) OTP 28+
- [Phoenix](https://phoenixframework.org/blog/phoenix-1-8-released) 1.8+

### Installation

#### 1. Add Dependency

Add Aurora UIX to your `mix.exs`:

```elixir
def deps do
  [
    {:aurora_uix, "~> 0.1.4"}
  ]
end
```

Then run:
```shell
mix deps.get
```

#### 2. Configure the Stylesheet

Aurora UIX ships with pre-built CSS themes (`light` and `dark` by default). Generate the stylesheet:

```shell
mix auix.gen.stylesheet
```

This creates `assets/css/auix-stylesheet.css`. Import it **at the end** of your `assets/css/app.css`:

```css
@import "./auix-stylesheet.css";
```

> **Important**: The Aurora UIX stylesheet must be the **last line** in `app.css` so its styles take priority over any conflicting rules.

> **Tip**: If you change the theme configuration or customize its style, re-run `mix auix.gen.stylesheet` to regenerate the stylesheet.

#### 3. Configure Icons (optional)

Aurora UIX uses **Heroicons** for all UI icons. If your project doesn't already use Heroicons, generate the icon CSS classes:

```shell
mix auix.gen.icons
```

Then add an import **at the top** of your `assets/css/app.css`:

```css
@import "auix-icons.css";
```

#### 4. Create Your First CRUD UI

Create a module (e.g., `lib/my_app_web/auix/product_ui.ex`) and use the example above. Then register LiveView routes in your router:

```elixir
scope "/inventory" do
  pipe_through(:browser)
  live "/products", Overview.Product.Index
  live "/products/new", Overview.Product.Index, :new
  live "/products/:id/edit", Overview.Product.Index, :edit
  live "/products/:id/show", Overview.Product.Index, :show
end
```

Or use the route helper for a shorter syntax:

```elixir
import Aurora.Uix.RouteHelper

scope "/inventory", Aurora.UixWeb.Guides do
  pipe_through(:browser)
  auix_live_resources("/products", Overview.Product)
end
```

### 📚 Next Steps

- **[Complete Getting Started Guide](./guides/introduction/getting_started.md)** — Detailed setup with a working example
- **[Resource Metadata Guide](./guides/core/resource_metadata.md)** — Learn field configuration, validation, and associations
- **[Layout System Guide](./guides/core/layouts.md)** — Master the layout DSL for complex UIs
- **[LiveView Integration](./guides/core/liveview.md)** — Handle events and business logic

---
## 💡 Use Cases

Aurora UIX excels in these scenarios:

| Use Case | Why Aurora UIX? |
|----------|----------------|
| **Admin Panels** | Generate admin dashboards for internal tools in hours, not weeks |
| **Data Management Apps** | Build CRUD-heavy applications focused on data entry and management |
| **Rapid Prototyping** | Quickly validate ideas and MVPs without UI boilerplate |
| **Internal Tools** | Create tools for your team without investing in custom UI |
| **CRUD-First Apps** | Applications where 80% of the UI is standard CRUD operations |

Aurora UIX is **best suited** when:
- Your primary need is CRUD operations with standard UI patterns
- You want compile-time safety and performance
- Consistency across the application is important
- You value maintainable, declarative configuration

---
## 📖 Documentation & Guides

Complete documentation is available in the [guides](./guides/overview/overview.md) and on [HexDocs](https://hexdocs.pm/aurora_uix):

- **[Overview](./guides/overview/overview.md)** — Architecture and core concepts
- **[Getting Started](./guides/introduction/getting_started.md)** — Installation and first CRUD UI
- **[Resource Metadata](./guides/core/resource_metadata.md)** — Field configuration and validation
- **[Layout System](./guides/core/layouts.md)** — Layout DSL and composition
- **[LiveView Integration](./guides/core/liveview.md)** — Event handling and business logic
- **[Advanced Usage](./guides/advanced/advanced_usage.md)** — Custom components and themes
- **[Troubleshooting](./guides/advanced/troubleshooting.md)** — Common issues and solutions

---
## 🚢 Deployment

Building your Aurora UIX application for production:

```bash
# Build the release
MIX_ENV=prod mix release

# Run the release
_build/prod/rel/aurora_uix/bin/aurora_uix start
```

For complete deployment guidance, see the [Phoenix Deployment Guide](https://hexdocs.pm/phoenix/deployment.html).

---
## 🤝 Contributing

We welcome contributions! Aurora UIX is maintained by WAdvanced and community members.

**Before contributing**, read the [Contributing Guidelines](CONTRIBUTING.md) which includes:
- How to report bugs and suggest features
- Development setup and testing procedures
- Code style and commit message conventions
- Pull request process

**Quick links:**
- [GitHub Issues](https://github.com/wadvanced/aurora_uix/issues) — Report bugs or suggest features
- [GitHub Discussions](https://github.com/wadvanced/aurora_uix/discussions) — Ask questions
- [Contributing Guidelines](CONTRIBUTING.md) — Full contribution details

---
## 📜 License

Licensed under the [MIT License](LICENSE.md).

---
## 📧 Contact

- **Email:** [contact@wadvanced.com](mailto:contact@wadvanced.com)
- **Repository:** [https://github.com/wadvanced/aurora_uix](https://github.com/wadvanced/aurora_uix)
