import Config

# Configure your database
config :aurora_uix, Aurora.Uix.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "aurora_uix_test",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we can use it
# to bundle .js and .css sources.
config :aurora_uix, Aurora.UixWeb.Endpoint,
  http: [ip: {0, 0, 0, 0}, port: String.to_integer(System.get_env("PORT") || "4001")],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "gs1QUYJOans/xmI8ulM3SrYrhPn9pim0OF0Ciji2NRabaXy5KLK/FkNwB3MYnAkB",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:aurora_uix, ~w(--sourcemap=inline --watch)]}
  ]

# Watch static and templates for browser reloading.
config :aurora_uix, Aurora.UixWeb.Endpoint,
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

# Do not include metadata nor timestamps in development logs
config :logger, :default_formatter, format: "[$level] $message\n"

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
