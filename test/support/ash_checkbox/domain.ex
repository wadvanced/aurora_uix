defmodule Aurora.UixWeb.Test.AshCheckbox.Domain do
  @moduledoc false
  use Ash.Domain

  resources do
    resource Aurora.UixWeb.Test.AshCheckbox.Item
  end
end
