defmodule Aurora.Uix.Repo do
  @moduledoc """
  Ecto repository for Aurora UIX with AshPostgres integration.

  Provides database operations and PostgreSQL extension management for Aurora UIX,
  configured specifically for Ash Framework compatibility with required extensions.

  ## Key Features
  - PostgreSQL database adapter via AshPostgres
  - UUID, case-insensitive text, and custom Ash function support
  - Minimum PostgreSQL version enforcement

  ## Key Constraints
  - Requires PostgreSQL 13.0.0 or higher
  - Depends on specific PostgreSQL extensions (uuid-ossp, citext, ash-functions)
  """
  use AshPostgres.Repo,
    otp_app: :aurora_uix,
    adapter: Ecto.Adapters.Postgres

  @doc """
  Returns the list of required PostgreSQL extensions.

  ## Returns
  list(String.t()) - List of extension names required by the repository.
  """
  @spec installed_extensions() :: list(String.t())
  def installed_extensions do
    ["uuid-ossp", "citext", "ash-functions"]
  end

  @doc """
  Returns the minimum supported PostgreSQL version.

  ## Returns
  Version.t() - The minimum PostgreSQL version struct (13.0.0).
  """
  @spec min_pg_version() :: Version.t()
  def min_pg_version do
    %Version{major: 13, minor: 0, patch: 0}
  end
end
