# aurora-uix
Low code UI for the elixir's Phoenix Framework.

## Installation

## Testing

### Requirements
- A running postgres server. Defaults to localhost:5432, username: postgres, password: postgres.
  The database is aurora_uix_test.
- The postgres server with the extension `uuid-ossp` created.
  ```sql
  create extension if not exists "uuid-ossp";
  ```
### Ecto
Ecto app is only available in the test environment. To run any ecto command use the following syntax:
```shell
MIX_ENV=test mix do test.setup, #ecto command

### Examples

# To create the database
MIX_ENV=test mix do test.setup, ecto create


# To run migrations
MIX_ENV=test mix do test.setup, ecto migrate
```

### Run tests
To run the tests simply:
```shell
mix test
```

To open the iex, and have the test environment available:
```shell
MIX_ENV=test iex --dot-iex "test/start_dependencies.exs" -S mix 
```

### Tests configuration
You can override the default environment configuration by creating a config/test.exs file.

For enabling the phx.server in the test environment it is needed ecto, postgres, tailwind, esbuild and the endpoint must be configured to serve.
Here is the equivalent test.exs for the default configuration within the code:
```elixir
import Config

### Repo
config :aurora_uix,
  ecto_repos: [AuroraUixTest.Repo]
  
### Postgres environment configuration
config :aurora_uix, AuroraUixTest.Repo,
  username: "postgres",
  password: "postgres",
  database: "aurora_uix_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10,
  migration_timestamps: [type: :utc_datetime]

config :aurora_uix, AuroraUixTestWeb.Endpoint,
  http: [port: 4001],
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  server: true, # Server must be enabled
  live_view: [signing_salt: "7aOSy6v8"],
  secret_key_base:
    "f59381a5df4c47aef696a74bb8dc09d086df3a69f05de01f0b72ef916c95c1285107acba5ce2dc738a6c6d5ee259faf98a1b18f83cfe00c82280b446fbb25fb3"

config :tailwind, 
  version: "3.4.6",
  aurora_uix: [
  args: [
        "--config=./tailwind.config.js",
        "--input=css/app.css",
        "--output=../_priv/static/assets/app.css"
      ],
      cd: Path.expand("assets", __DIR__)
  ]

config :esbuild, 
  version: "0.23.0",
  aurora_uix: [
      args: [
        "js/app.js",
        "--bundle",
        "--target=es2017",
        "--outdir=../_priv/static/assets",
        "--external:/fonts/*",
        "--external:/images/*"
      ],
      cd: Path.expand("assets", __DIR__),
      env: %{
        "NODE_PATH" => "../../deps"
      }    
  ]
```

You can create and modify its content to meet your test environment.

## Contributing
PR are welcomed, we encourage code quality, so PR must pass the mix consistency task. It does:
* Re-formats code with mix `format`.
* Compiles with `--warnings-as-errors`.
* Applies strict credo analysis using mix `credo` --strict.
* Runs dialyzer with mix `dialyzer`.
* Verify documentation healthiness with mix `doctor`.

The formatter credo and doctor have configuration files have been authored according to this project code quality checks. 
However, rules changes can be accepted.

## License

This project is licensed under the [MIT License](LICENSE.md).  
This means you are free to:

- Use, copy, and modify the code for personal or commercial purposes.
- Distribute and sublicense copies of the code.
- Include this library in proprietary software.

For full details, see the [LICENSE](LICENSE.md) file in this repository.
