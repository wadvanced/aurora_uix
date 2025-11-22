defmodule Aurora.Uix.Accounts do
  @moduledoc """
  Provides guides and test context for user accounts in the Aurora.Uix application. 
  This module and its children are excluded from package builds and documentation, 
  since they are intended for use in test and dev environments only.


  This module registers the User schema with the Repo for use in guides and test scenarios.
  """

  use Aurora.Ctx

  alias Aurora.Uix.Accounts.User
  alias Aurora.Uix.Repo

  ctx_register_schema(User, Repo)
end
