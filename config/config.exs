# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :aurora_uix,
  ecto_repos: [Aurora.Uix.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :aurora_uix, Aurora.UixWeb.Endpoint,
  url: [host: "localhost"],
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("PORT") || "4001")],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: Aurora.UixWeb.ErrorHTML, json: Aurora.UixWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Aurora.Uix.PubSub,
  live_view: [signing_salt: "I9hzS6Y2"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  aurora_uix: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.7",
  aurora_uix: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
      --content=./lib/**/*.{ex,heex,eex}
      --content=./assets/js/**/*.js
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
