defmodule AuroraUixTestWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :aurora_uix

  socket("/socket", Phoenix.LiveView.Socket, websocket: true)
end
