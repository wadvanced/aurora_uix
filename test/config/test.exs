import Config

### Repo
config :aurora_uix,
  ecto_repos: [Aurora.Uix.Test.Repo]

### Postgres environment configuration
config :aurora_uix, Aurora.Uix.Test.Repo,
  username: "postgres",
  password: "postgres",
  database: "aurora_uix_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10,
  migration_timestamps: [type: :utc_datetime]

### Phoenix environment default configuration
config :aurora_uix, Aurora.Uix.Test.Web.Endpoint,
  http: [port: 4001],
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  check_origin: false,
  # Server must be enabled
  server: true,
  live_view: [signing_salt: "7aOSy6v8"],
  secret_key_base:
    "f59381a5df4c47aef696a74bb8dc09d086df3a69f05de01f0b72ef916c95c1285107acba5ce2dc738a6c6d5ee259faf98a1b18f83cfe00c82280b446fbb25fb3",
  watchers: [
    # Start the esbuild watcher by calling Esbuild.install_and_run(:default, args)
    esbuild: {Esbuild, :install_and_run, [:aurora_uix, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:aurora_uix, ~w(--watch)]}
  ]

# Tailwind environment
config :tailwind,
  version: "3.4.6",
  aurora_uix: [
    args: [
      "--config=./tailwind.config.js",
      "--input=css/app.css",
      "--output=../_priv/static/assets/app.css"
    ],
    cd: Path.expand("../assets", __DIR__)
  ]

# esbuild environment
config :esbuild,
  version: "0.23.0",
  aurora_uix: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{
      "NODE_PATH" => "../../deps"
    }
  ]

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  # Include debug annotations and locations in rendered markup.
  # Changing this configuration will require mix clean and a full recompile.
  debug_heex_annotations: true,
  debug_attributes: true,
  # Enable helpful, but potentially expensive runtime checks
  enable_expensive_runtime_checks: true
