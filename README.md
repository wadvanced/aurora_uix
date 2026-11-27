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

> 🚀 **New to Elixir or Phoenix?** Follow the **[Build Your First App tutorial](./guides/tutorial/build_your_first_app.md)** — a copy-paste walkthrough from nothing installed to a running CRUD app.

---
## 📖 Overview

Aurora UIX is a metadata-driven UI framework for Elixir's Phoenix LiveView that lets you rapidly generate complete CRUD interfaces from your Ecto schemas or Ash resources. Instead of writing repetitive form and list code, define your resource once and get a fully functional, responsive UI with built-in validation, association handling, and real-time updates.

**Why Aurora UIX?**
- **Rapid Development** — Build CRUD interfaces in minutes, not days. Define resource metadata once, get complete index, show, and edit views.
- **Compile-Time Generation** — The UI modules are generated when your application compiles, and mistakes in a declaration fail the build.
- **Extensible by Design** — Customize every layer: field renderers, layouts, components, themes, and LiveView event handlers.
- **Production-Ready Features** — Built-in pagination, validation, error handling, i18n, responsive design, and real-time updates via LiveView.

**Key Features:**

### Generate

- **Complete CRUD views** - Index, show and form views from your resource metadata and layouts
- **Two backends** - Ecto schemas with [`aurora_ctx`](https://hexdocs.pm/aurora_ctx) contexts, or Ash resources, detected automatically
- **Associations and embeds** - `belongs_to`, `has_many`, `has_one`, `many_to_many`, `embeds_one` and `embeds_many`
- **File uploads** - An [`upload` block](./guides/core/resource_metadata.md#file-uploads) turns a field into a LiveView upload
- **Compile-time checks** - An unknown or mistyped DSL option fails compilation at the line that declares it

### Work with data

- **Filtering and sorting** - Filters on the index fields (turn one off with `filterable?: false`), sortable column headers, and `where` and `order_by` to scope a list
- **Pagination** - Pages in the table, infinite scroll in the card view
- **Live updates** - With a PubSub server configured, [open lists re-read their page](./guides/core/liveview.md#reacting-to-data-changes) when another session saves or deletes a record
- **Ash authorization** - The current actor is [passed to every generated call](./guides/core/ash_integration.md#authorization-and-policies), so your policies apply
- **Ash calculations and aggregates** - [Discovered and loaded](./guides/core/ash_integration.md#calculations-and-aggregates) like any other field

### Embed

- **[Reusable components](./guides/core/components.md)** - Place the generated index, form and show views inside LiveViews you write

### Adapt

- **Layouts** - Compose `inline`, `stacked`, `group` and `sections`, and [reuse layouts](./guides/core/layouts.md#reusable-layouts) across modules with `include:`
- **Responsive cards** - Small screens show [one card per record](./guides/core/layouts.md#index-cards); a layout can design the card and show it at every width
- **Themes** - White Charcoal, Vitreous Marble and Blue Graphite, in light and dark, or [your own](./guides/customization/theming.md)
- **Actions** - [Add, replace or remove buttons](./guides/customization/custom_actions.md), change their icons, and run [bulk actions](./guides/customization/custom_actions.md#bulk-actions-on-selected-rows) on selected rows
- **Renderers and components** - Built-in field renderers such as toggle switch, badge, progress bar and rating, your own renderers and [component overrides](./guides/customization/customization.md)
- **Behavior** - [Handler hooks](./guides/core/liveview.md#handler-hooks) for your business logic
- **Internationalization** - A [configurable Gettext backend](./guides/core/internationalization.md)

### Technology Stack
- Elixir `1.17+`
- Phoenix `1.8+`
- Phoenix LiveView `1.2+`
- Ecto `3.14+`

---
## ⚡ Quick Example

See Aurora UIX in action. In just a few lines of code, generate a complete, responsive product management interface:

```elixir
defmodule MyAppWeb.Products do
  use Aurora.Uix
  alias MyApp.Inventory.Product

  # 1. Define resource metadata (once)
  auix_resource_metadata :product do
    context MyApp.Inventory
    schema Product
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

- [Elixir](https://elixir-lang.org/install.html) 1.17+, with an [Erlang/OTP](https://www.erlang.org/downloads) release it supports
- [Phoenix](https://hexdocs.pm/phoenix/installation.html) 1.8+ and Phoenix LiveView 1.2+

### Installation

Add Aurora UIX to your `mix.exs`:

```elixir
def deps do
  [
    {:aurora_uix, "~> 0.2.1"}
  ]
end
```

Aurora UIX needs `phoenix_live_view ~> 1.2`. If your project pins an older version, as some
`mix phx.new` releases do, raise it before running `mix deps.get`.

Then follow [Getting Started](./guides/introduction/getting_started.md):

1. [Generate and import the stylesheet](./guides/introduction/getting_started.md#css-configuration)
2. [Set up the icons](./guides/introduction/getting_started.md#icons-configuration)
3. [Import the JavaScript hooks](./guides/introduction/getting_started.md#javascript-setup)
4. [Declare your UI and add its routes](./guides/introduction/getting_started.md#basic-usage)

### 📚 Next Steps

- **[Build Your First App](./guides/tutorial/build_your_first_app.md)** — Zero-background, end-to-end tutorial: install the toolchain and build a complete app from scratch
- **[Complete Getting Started Guide](./guides/introduction/getting_started.md)** — Detailed setup with a working example
- **[Resource Metadata Guide](./guides/core/resource_metadata.md)** — Learn field configuration, validation, and associations
- **[Layout System Guide](./guides/core/layouts.md)** — Master the layout DSL for complex UIs
- **[LiveView Integration](./guides/core/liveview.md)** — Handle events and business logic
- **Make it look like your app** → [Customizing & Extending Aurora UIX](./guides/customization/customization.md) — styling, theming, component overrides, and custom actions in one place

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

- **[Build Your First App](./guides/tutorial/build_your_first_app.md)** — Zero-background tutorial: from nothing installed to a running CRUD app
- **[Overview](./guides/overview/overview.md)** — Architecture and core concepts
- **[Getting Started](./guides/introduction/getting_started.md)** — Installation and first CRUD UI
- **[What's New](./guides/whats_new/0.2.1.md)** — Headline changes of 0.2.1 with upgrade notes and examples; one page is kept per release in `guides/whats_new/`
- **[Resource Metadata](./guides/core/resource_metadata.md)** — Field configuration and validation
- **[Layout System](./guides/core/layouts.md)** — Layout DSL and composition
- **[Reusable Components](./guides/core/components.md)** — Embed the index, form and show components in your own LiveViews
- **[LiveView Integration](./guides/core/liveview.md)** — Event handling and business logic
- **[Customizing & Extending](./guides/customization/customization.md)** — Central hub for styling, theming, component overrides, and custom actions
- **[Styling](./guides/customization/styling.md)** — Host styling with `--auix-*` variable overrides and the cascade-layer model
- **[Internationalization](./guides/core/internationalization.md)** — Configuring the Gettext backend, automatic POT generation, and translation workflow
- **[CSS Bridges](./guides/customization/writing_a_style_bridge.md)** — Mapping host design-system tokens onto `--auix-*` variables
- **[Advanced Usage](./guides/advanced/advanced_usage.md)** — Templates, metadata separation and custom backends
- **[Troubleshooting](./guides/advanced/troubleshooting.md)** — Common issues and solutions

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
