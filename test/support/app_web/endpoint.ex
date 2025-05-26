defmodule Aurora.Uix.Web.Test.Endpoint do
  use Phoenix.Endpoint, otp_app: :aurora_uix

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_aurora_uix_test_key",
    signing_salt: "17ECouB/",
    same_site: "Lax"
  ]

  socket("/live", Phoenix.LiveView.Socket)

  plug(Plug.Static,
    at: "/",
    from: "test/_priv/static",
    gzip: false,
    only: Aurora.Uix.Web.Test.static_paths()
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
  plug(Aurora.Uix.Web.Test.Router)
end
