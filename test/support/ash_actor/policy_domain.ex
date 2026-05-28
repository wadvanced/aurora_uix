defmodule AshActorTest.PolicyDomain do
  @moduledoc false
  use Ash.Domain

  resources do
    resource AshActorTest.PolicyItem
    resource AshActorTest.PolicyItemScope
    resource AshActorTest.PublicItem
  end
end
