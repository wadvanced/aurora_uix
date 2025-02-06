# Load file config/test.exs
configuration_file = "config/test.exs"

# Tries to load the test.exs configuration file
if File.exists?(configuration_file) do
  configuration_file
  |> Config.Reader.read!()
  |> Enum.each(fn {app, configs} ->
    Enum.each(configs, fn {key, value} ->
      Application.put_env(app, key, value)
    end)
  end)
end

## Set default environment, if not set in a configuration file.

### Repo
if is_nil(Application.get_env(:aurora_uix, :ecto_repos)),
  do: Application.put_env(:aurora_uix, :ecto_repos, [AuroraUixTest.Repo])

### Postgres environment default configuration
if is_nil(Application.get_env(:aurora_uix, AuroraUixTest.Repo)),
  do:
    Application.put_env(:aurora_uix, AuroraUixTest.Repo,
      username: "postgres",
      password: "postgres",
      database: "aurora_uix_test",
      hostname: "localhost",
      pool: Ecto.Adapters.SQL.Sandbox,
      pool_size: 10,
      migration_timestamps: [type: :utc_datetime]
    )

### Phoenix environment default configuration
if is_nil(Application.get_env(:aurora_uix, AuroraUixTestWeb.Endpoint)),
  do:
    Application.put_env(:aurora_uix, AuroraUixTestWeb.Endpoint,
      http: [port: 4001],
      url: [host: "localhost"],
      adapter: Bandit.PhoenixAdapter,
      # Server must be enabled
      server: true,
      live_view: [signing_salt: "7aOSy6v8"],
      secret_key_base:
        "f59381a5df4c47aef696a74bb8dc09d086df3a69f05de01f0b72ef916c95c1285107acba5ce2dc738a6c6d5ee259faf98a1b18f83cfe00c82280b446fbb25fb3"
    )

# Tailwind environment
if is_nil(Application.get_env(:tailwind, :version)),
  do: Application.put_env(:tailwind, :version, "3.4.6")

if is_nil(Application.get_env(:tailwind, :aurora_uix)),
  do:
    Application.put_env(:tailwind, :aurora_uix,
      args: [
        "--config=./tailwind.config.js",
        "--input=css/app.css",
        "--output=../_priv/static/assets/app.css"
      ],
      cd: Path.expand("assets", __DIR__)
    )

# ESBuild environment
if is_nil(Application.get_env(:esbuild, :version)),
  do: Application.put_env(:esbuild, :version, "0.23.0")

if is_nil(Application.get_env(:esbuild, :aurora_uix)),
  do:
    Application.put_env(:esbuild, :aurora_uix,
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
    )
