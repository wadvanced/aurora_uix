defmodule AuroraUixTest.Repo do
  use Ecto.Repo,
    otp_app: :aurora_uix,
    adapter: Ecto.Adapters.Postgres
end
