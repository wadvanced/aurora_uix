import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :aurora_uix, Aurora.Uix.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "aurora_uix_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# Configure modules
config :aurora_uix,
  endpoint: Aurora.UixWeb.Test.Endpoint

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we can use it
# to bundle .js and .css sources.
config :aurora_uix, Aurora.UixWeb.Test.Endpoint,
  http: [ip: {0, 0, 0, 0}, port: String.to_integer(System.get_env("PORT") || "4001")],
  adapter: Bandit.PhoenixAdapter,
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  server: true,
  secret_key_base: "IxHRUjPWSSjebX94pT1TbP1TojKBJmMzFFklknykyzf0EkuvGLrcG5I54+kTQzg3",
  live_view: [signing_salt: "I9hzS6Y2"],
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:aurora_uix, ~w(--sourcemap=inline --watch)]}
  ]

# Enable dev routes for dashboard
config :aurora_uix, dev_routes: true

# Enable test routes
config :aurora_uix, test_routes: true, start_application: true

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
