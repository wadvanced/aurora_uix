defmodule Aurora.UixWeb.Test.Endpoint do
  @moduledoc """
  The application's entry point for web requests.

  It defines the endpoint's configuration and the plug pipeline
  that all requests go through.
  """
  use Phoenix.Endpoint, otp_app: :aurora_uix

  alias Aurora.UixWeb.Test, as: TestWeb
  alias Aurora.UixWeb.Test.Router, as: TestRouter

  alias Phoenix.LiveView.Socket

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_aurora_uix_key",
    signing_salt: "17ECouB/",
    same_site: "Lax"
  ]

  socket("/live", Socket,
    websocket: [connect_info: [:user_agent, session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]
  )

  plug(Plug.Static,
    at: "/",
    from: "priv/static",
    gzip: false,
    only: TestWeb.static_paths()
  )

  plug(Plug.RequestId)
  plug(Plug.Telemetry, event_prefix: [:phoenix, :endpoint])

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)
  plug(Plug.Session, @session_options)
  plug(TestRouter)
end
