defmodule Aurora.Uix.Repo do
  @moduledoc """
  Ecto repository for Aurora UIX test support.

  ## Key Features
  - Used for database operations in test modules and helpers.
  """
  use AshPostgres.Repo,
    otp_app: :aurora_uix,
    adapter: Ecto.Adapters.Postgres

  def installed_extensions do
    ["uuid-ossp", "citext", "ash-functions"]
  end

  def min_pg_version do
    %Version{major: 13, minor: 0, patch: 0}
  end
end
