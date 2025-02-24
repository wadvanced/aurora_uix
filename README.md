# aurora-uix
A low code UI for the elixir's Phoenix Framework.

---
## For Users
### Installation
Add `aurora_uix` to your `mix.exs` dependencies:
```elixir
def deps do
  [
    {:aurora_uix, "~> 0.1.0"}
  ]
end
```
Then, install the dependencies:
```shell
mix deps.get
```

### Usage
Aurora UIx is designed to simplify UI development in Phoenix applications. 
To get started, follow the Phoenix Framework documentation and integrate 
the Aurora UIx library.

For detailed usage instructions, refer to the [documentation]()

---
## For Contributors
Thank you for considering contributing to Aurora UIx! 
Here’s how to set up your development and testing environment.

### Requirements
- **Elixir**: Ensure Elixir is installed. You can check by running:
  ```shell
  ~$ elixir --version
  ```
- **PostgreSQL**: Ensure a PostgreSQL server is running. Default configuration:
  - Host: localhost: 5432
  - Username: postgres
  - Password: postgres
  - Database: aurora_uix_test
- **UUID Extension**: Ensure that the `uuid-ossp` extension is enabled in PostgreSQL:
  ```sql
  CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
  ```

### Setting Up the Environment
1. Clone the repository:
```shell
~$ git clone https://github.com/your-repo/aurora-uix.git
~$ cd aurora-uix
```
2. Install dependencies:
```shell
~$ mix deps.get
```
3. Install Tailwind and esbuild assets:
```shell
~$ mix test.assets.install
```
4. Build Tailwind and esbuild assets:
```shell
~$ mix test.assets.build
```
5. Create the test database:
```shell
~$ mix test.task ecto.create
```
6. Run migrations:
```shell
~$ mix test.task ecto.migrate
```
7. **(Optional)** Override the default test configuration:<br>
If you need to customize the test environment, 
you can create a `config/test.exs` file. 
The library provides default configurations, 
so this step is only necessary if you need to override them. 
Here’s an example of what the file might look like:

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
### Running Tests
* Run all tests:
```shell
~$ mix test
```
* Start and interactive `iex` session with the test environment:
```shell
MIX_ENV=test iex --dot-iex "test/start_dependencies.exs" -S mix
```

### Contribution Guidelines
We welcome contributions! Please ensure your pull requests pass the following checks:
1. **Run the consistency check**:<br>
The `mix consistency` task ensures that your code meets the project's quality standards.
It performs the following checks:
* Code formatting with `mix format`.
* Compilation with `--warnings-as-errors`.
* Strict credo analysis with `mix credo --strict`.
* Dialyzer checks with `mix dialyzer`.
* Documentation health with `mix doctor`.

Run it with:
```shell
~$ mix consistency
```
2. **Ensure all tests pass**:<br>
Run the test suite and verify that all tests are successful:
```shell
mix test
```
3. **Follow coding standards**:<br>
* Use the provided formatter and Credo configurations.
* Write clear and concise documentation where applicable.

Configuration files for formatter, Credo, and Doctor are provided. 
Rule changes may be considered.

## License

This project is licensed under the [MIT License](LICENSE.md).  
This means you are free to:

- Use, copy, and modify the code for personal or commercial purposes.
- Distribute and sublicense copies of the code.
- Include this library in proprietary software.

For full details, see the [LICENSE](LICENSE.md) file.
