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

A low-code UI framework for Elixir's Phoenix, generating CRUD UIs with minimal code.

---
## 📖 Overview

Aurora UIX is a low-code UI framework for Elixir's Phoenix LiveView that helps you build feature-rich CRUD interfaces with minimal configuration. It is designed to be highly extensible, allowing you to customize every aspect of the UI, from fields and layouts to actions and templates.

- **Key Features**:
  - **Low-Code**: Generate complete CRUD UIs from your Ecto schemas with just a few lines of code.
  - **Highly Extensible**: Customize fields, layouts, actions, and templates to fit your needs.
  - **LiveView Native**: Built on top of Phoenix LiveView for real-time user experiences.
  - **Association Support**: Built-in support for `belongs_to` and `has_many` associations.
- **Technology Stack**:
  - Elixir `1.15.x`
  - Phoenix `1.7.x`
  - Ecto `3.10.x`

---
## 🚀 Getting Started

### Prerequisites

Ensure you have the following installed on your local machine:
- [Elixir](https://elixir-lang.org/install.html)
- [Erlang](https://www.erlang.org/downloads)

### Installation

1. **Add to your dependencies**  
   In `mix.exs`:
   ```elixir
   def deps do
     [
       {:aurora_uix, "~> 0.1.0"}
     ]
   end
   ```
   Then run:
   ```shell
   mix deps.get
   ```

2. **Configure Tailwind**  
   Add Aurora UIX to your `tailwind.config.js`:
   ```js
   module.exports = {
     content: [
       "./js/**/*.js",
       "../lib/aurora_uix_demo_web.ex",
       "../lib/aurora_uix_demo_web/**/*.*ex",
       "../dev/aurora_uix/**/*.ex"
     ],
     // ...
   }
   ```

3. **Next Steps**  
   - Learn how to define resources, layouts, and customize your UI in the [Getting Started Guide](./guides/introduction/getting_started.md).
   - For advanced configuration, see the [full documentation](#-documentation--guides).

---

### 📚 Documentation & Guides

- [Getting Started](./guides/introduction/getting_started.md)
- [Resource Metadata](./guides/core/resource_metadata.md)
- [Layout System](./guides/core/layouts.md)
- [Customizing Fields](./guides/core/fields.md)
- [LiveView Integration](./guides/core/liveview.md)
- [Advanced Usage](./guides/advanced/advanced_usage.md)
- [Troubleshooting](./guides/advanced/troubleshooting.md)

Find all guides in the [`guides/`](./guides/) directory.

---

> 💡 **Tips**
>
> - **Styling**: If you see unexpected layout constraints, check for `max-w-2xl` or similar classes in your `app.html.heex` and remove them for full-width layouts.
> - **Field Customization**: Use field options like `readonly`, `hidden`, `renderer`, and `option_label` for fine-grained control.
> - **Associations**: Aurora UIX supports both `has_many` and `belongs_to` associations with customizable labels.

---
## 🧪 Running Tests

- Run all tests:
  ```shell
  mix test
  ```
- Start an interactive test app:
  ```shell
  MIX_ENV=test iex --dot-iex "test/start_test_app.exs" -S mix
  ```
- Start the test server with all live cases:
  ```shell
  MIX_ENV=test iex --dot-iex "test/start_test_server.exs" -S mix
  ```
- Run the consistency check:
  ```shell
  mix consistency
  ```
  This checks formatting, compilation, Credo, Dialyzer, and documentation.

- Follow the provided formatter, Credo, and Doctor configs.

#### Test UI Setup: Router

  Example:
  ```elixir
  auix_create_ui do
    # ...
  end
  ```
- The generated module name is used to register routes in the test router.
- See [`test/support/app_web/router.ex`](test/support/app_web/router.ex) for how all test CRUD UIs are registered using `register_crud` and `register_product_crud`.
- This setup is required for the test server to mount and test all CRUD UIs at predictable URLs.

---
## 🚢 Deployment

- **Building for production:**
  ```bash
  MIX_ENV=prod mix release
  ```
- **Running migrations in production:**
  ```bash
  prod/rel/[your-app]/bin/[your-app] eval "MyApp.Release.migrate"
  ```
- **Hosting details** (e.g., Gigalixir, Fly.io, or self-hosted).

---
## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guidelines](CONTRIBUTING.md) to get started.

---
## 📜 License

This project is licensed under the [MIT License](LICENSE).

---
## 📧 Contact

- **WAdvanced** - contact@wadvanced.com
- **Project Link** - [https://github.com/wadvanced/aurora_uix](https://github.com/wadvanced/aurora_uix)
