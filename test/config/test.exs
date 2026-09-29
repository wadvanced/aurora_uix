# This configuration is ALWAYS read during development,
# HOWEVER, you can author a config/test.exs file with the keys
# that you need to override in order to meet your requirements

import Config

checkout_root = Path.expand("../..", __DIR__)

# Every checkout (main clone or git worktree) tests against its own disposable
# PostgreSQL instance (scripts/test_pg.sh), reached through a Unix socket, so
# concurrent `mix test` runs never share a server or a database. CI keeps its
# service container (`CI` is set there); AURORA_UIX_TEST_PG=shared opts a shell
# back into the plain localhost connection below.
private_test_instance? =
  System.get_env("CI") == nil and System.get_env("AURORA_UIX_TEST_PG") != "shared"

test_database_socket =
  if private_test_instance? do
    script = Path.join(checkout_root, "scripts/test_pg.sh")

    case System.cmd(script, ["ensure"], cd: checkout_root, stderr_to_stdout: true) do
      {output, 0} ->
        [socket_dir: output |> String.trim() |> String.split("\n") |> List.last()]

      {output, status} ->
        raise "scripts/test_pg.sh ensure failed (exit #{status}):\n#{output}"
    end
  else
    []
  end

# The main checkout keeps 4001; a linked worktree (its `.git` is a file) derives
# its port from its own path, so concurrent suites never bind the same port.
# Wallaby's base_url follows the same port. PORT always wins.
linked_worktree? = checkout_root |> Path.join(".git") |> File.regular?()

default_port =
  if linked_worktree?,
    do: 40_000 + :erlang.phash2(checkout_root, 10_000),
    else: 4001

test_port =
  case System.get_env("PORT") do
    nil -> default_port
    port -> String.to_integer(port)
  end

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :aurora_uix,
       Aurora.Uix.Repo,
       [
         username: "postgres",
         password: "postgres",
         hostname: "localhost",
         database: "aurora_uix_test#{System.get_env("MIX_TEST_PARTITION")}",
         pool: Ecto.Adapters.SQL.Sandbox,
         pool_size: System.schedulers_online() * 2
       ] ++ test_database_socket

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
  http: [ip: {0, 0, 0, 0}, port: test_port],
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
config :logger,
  level: :error,
  truncate: :infinity

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

config :wallaby,
  base_url: "http://localhost:#{test_port}",
  driver: Wallaby.Chrome,
  screenshot_on_failure: true,
  screenshot_dir: "tmp",
  hackney_options: [timeout: 5_000],
  js_logger: nil,
  chromedriver: [
    headless: System.get_env("WALLABY_CHROME_HEADLESS", "true") == "true",
    javascriptEnabled: false,
    fullscreen: false
  ]
