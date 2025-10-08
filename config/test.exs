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

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :aurora_uix, Aurora.UixWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4001],
  secret_key_base: "IxHRUjPWSSjebX94pT1TbP1TojKBJmMzFFklknykyzf0EkuvGLrcG5I54+kTQzg3",
  server: true

config :aurora_uix, test_routes: true

config :aurora_uix, test_routes_module: quote(do: use(Aurora.UixWeb.Test.Routes))

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
