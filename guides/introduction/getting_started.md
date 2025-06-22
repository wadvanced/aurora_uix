# Getting Started

Welcome to **Aurora UIX**! This guide will help you set up the library and build your first UI.

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

## Tailwind and Assets

Add Aurora UIX to your `tailwind.config.js`:

```js
module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/aurora_uix_demo_web.ex",
    "../lib/aurora_uix_demo_web/**/*.*ex",
    "../dev/aurora_uix/**/*.ex"
  ],
  // ...existing code...
}
```

Install Tailwind and esbuild assets:

```shell
mix uix.test.assets.install
mix uix.test.assets.build
```

## Database Setup

Ensure PostgreSQL is running and the `uuid-ossp` extension is enabled:

```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```

Create and migrate the test database:

```shell
mix uix.test.task ecto.create
mix uix.test.task ecto.migrate
```

## Running the Test App

Start the test app:

```shell
MIX_ENV=test iex --dot-iex "test/start_test_app.exs" -S mix
```

Visit [http://localhost:4001/products](http://localhost:4001/products) to see the UI.

## Next Steps
- [Customizing Fields](../../guides/core/fields.md)
- [Resource Metadata](../../guides/core/resource_metadata.md)
