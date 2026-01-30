defmodule Aurora.Uix.Guides.Accounts do
  @moduledoc """
  Provides guides and test context for user accounts.

  Registers the User schema with the Repo for use in guides and test scenarios.
  This module and its children are excluded from package builds and documentation.

  ## Key Features

  - User schema registration for test and guide scenarios
  - Integration with Aurora.Ctx for context operations

  ## Key Constraints

  - Only for test and development environments
  - Not included in production builds
  """

  use Aurora.Ctx

  alias Aurora.Uix.Guides.Accounts.User
  alias Aurora.Uix.Repo

  ctx_register_schema(User, Repo)
end
