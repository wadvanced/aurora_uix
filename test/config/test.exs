# This configuration is ALWAYS read during development,
# HOWEVER, you can author a config/test.exs file with the keys
# that you need to override in order to meet your requirements

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
  endpoint: Aurora.UixWeb.Test.Endpoint,
  sandbox: Ecto.Adapters.SQL.Sandbox

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
  pubsub_server: Aurora.Uix.PubSub,
  live_view: [signing_salt: "I9hzS6Y2"],
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:aurora_uix, ~w(--sourcemap=inline --watch)]}
  ]

# Watch static and templates for browser reloading.
config :aurora_uix, Aurora.UixWeb.Test.Endpoint,
  live_reload: [
    web_console_logger: true,
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/aurora_uix_web/(?:controllers|live|components|router)/?.*\.(ex|heex)$"
    ]
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

config :wallaby,
  base_url: "http://localhost:4001",
  driver: Wallaby.Chrome,
  screenshot_on_failure: true,
  screenshot_dir: "tmp",
  hackney_options: [timeout: 5_000],
  chromedriver: [
    headless: true,
    javascriptEnabled: false
  ]
