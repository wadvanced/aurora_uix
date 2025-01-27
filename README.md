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
```
- To create the database
```shell
MIX_ENV=test mix do test.setup, ecto create
```

- To run migrations
```shell
MIX_ENV=test mix do test.setup, ecto migrate
```

### Run tests
To run the tests simply:
```shell
mix test
```


### Tests configuration
You can override the default environment configuration by creating a config/test.exs file.

Here is the equivalent test.exs for the default configuration:
```elixir
import Config

config :aurora_uix, AuroraUixTestWeb.Endpoint,
  http: [port: 4001],
  server: false

config :aurora_uix,
  ecto_repos: [AuroraUixTest.Repo]
  
config :aurora_uix, AuroraUixTest.Repo,
  username: "postgres",
  password: "postgres",
  database: "aurora_uix_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10,
  migration_timestamps: [type: :utc_datetime]
```

You can create and modify its content to meet your test environment.

## Contributing
PR are welcomed, we encourage code quality, so PR must pass the mix consistency task. It do:
* Re-formats code with mix `format`.
* Compiles with `--warnings-as-errors`.
* Applies strict credo analysis using mix `credo` --strict.
* Runs dialyzer with mix `dialyzer`.
* Verify documentation healthiness with mix `doctor`.

The formatter credo and doctor have configuration files have been authored according to this project code quality checks. 
However rules changes can be accepted.

## License

This project is licensed under the [MIT License](LICENSE.md).  
This means you are free to:

- Use, copy, and modify the code for personal or commercial purposes.
- Distribute and sublicense copies of the code.
- Include this library in proprietary software.

For full details, see the [LICENSE](LICENSE.md) file in this repository.
