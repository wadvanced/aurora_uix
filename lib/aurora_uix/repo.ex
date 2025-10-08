defmodule Aurora.Uix.Repo do
  @moduledoc """
  Ecto repository for Aurora UIX test support.

  ## Key Features
  - Used for database operations in test modules and helpers.
  """
  use Ecto.Repo,
    otp_app: :aurora_uix,
    adapter: Ecto.Adapters.Postgres
end
