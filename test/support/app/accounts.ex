defmodule Aurora.Uix.Test.Accounts do
  @moduledoc """
  Provides test context for user accounts in the Aurora.Uix application.

  This module registers the test User schema with the Repo for use in test scenarios.
  """

  use Aurora.Ctx

  alias Aurora.Uix.Repo
  alias Aurora.Uix.Test.Accounts.User

  def list_users do
    Repo.all(User)
  end

  ctx_register_schema(User, Repo)
end
