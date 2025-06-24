<p align="center">
  <img src="./guides/images/aurora_uix-logo.svg" height="200" />
</p>

# Aurora UIX

A low-code UI framework for Elixir's Phoenix, generating CRUD UIs with minimal code.

---

## For Library Users

### 🚀 Getting Started

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

## For Contributors

Thank you for considering contributing! Here's how to set up your development and testing environment.

### 🛠️ Development Setup

- **Elixir** (check with `elixir --version`)
- **PostgreSQL** (default: localhost:5432, user: postgres, db: aurora_uix_test)
- **UUID Extension** in PostgreSQL:
  ```sql
  CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
  ```

1. Clone the repo:
   ```shell
   git clone https://github.com/your-repo/aurora-uix.git
   cd aurora-uix
   ```
2. Install dependencies:
   ```shell
   mix deps.get
   ```
3. Install and build assets:
   ```shell
   mix uix.test.assets.install
   mix uix.test.assets.build
   ```
4. Create and migrate the test database:
   ```shell
   mix uix.test.task ecto.create
   mix uix.test.task ecto.migrate
   ```
5. **(Optional) Custom Test Config**  
   - Copy `test/config/test.exs` to `config/test.exs` in your project root:
     ```shell
     cp test/config/test.exs config/test.exs
     ```
   - Edit `config/test.exs` as needed for your local environment.  
   - This file is not under version control.

---

### 🧪 Testing

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

#### Test UI Setup: Unique Link Option & Router

- **Each test UI must have a unique `link_prefix` in its `auix_create_ui` block.**  
  Example:
  ```elixir
  auix_create_ui link_prefix: "create-ui-layout-" do
    # ...
  end
  ```
- The generated module name and link prefix are used to register routes in the test router.
- See [`test/support/app_web/router.ex`](test/support/app_web/router.ex) for how all test CRUD UIs are registered using `register_crud` and `register_product_crud`.
- This setup is required for the test server to mount and test all CRUD UIs at predictable URLs.

---

### 🧩 Extending Aurora UIX

Aurora UIX is designed for extensibility. You can:

- **Create custom templates** by implementing the `Aurora.Uix.Template` behaviour. See [Advanced Usage](./guides/advanced/advanced_usage.md).
- **Override core components** using your own module with `Aurora.Uix.Web.CoreComponentsImporter`.
- **Add new field renderers or layout containers** by following the patterns in the `lib/aurora_uix/templates` directory.

For more, see the [Advanced Usage Guide](./guides/advanced/advanced_usage.md).

---

### 🤝 Contribution Guidelines

- All contributions must pass:
  - `mix consistency` (checks formatting, compilation, Credo, Dialyzer, and documentation)
  - `mix test` (all tests must pass)
- Please follow the provided formatter, Credo, and Doctor configs.
- Write clear and concise documentation where applicable.

---

## License

Aurora UIX is licensed under the [MIT License](LICENSE.md).

---
