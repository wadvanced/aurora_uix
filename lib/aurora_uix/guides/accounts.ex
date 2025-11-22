defmodule Aurora.Uix.Accounts do
  @moduledoc """
  Provides test context for user accounts in the Aurora.Uix application.

  This module registers the test User schema with the Repo for use in test scenarios.
  """

  use Aurora.Ctx

  alias Aurora.Uix.Accounts.User
  alias Aurora.Uix.Repo

  ctx_register_schema(User, Repo)
end
