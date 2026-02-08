defmodule Aurora.Uix.Guides.Blog.Tag do
  @moduledoc """
  Embedded Ash resource representing blog tags for guides and examples.

  ## Key Features

  - Embedded resource with no database persistence
  - Single name attribute for tag identification

  ## Key Constraints

  - Only for guides and test scenarios
  - Cannot be queried directly, only as embedded data
  """
  use Ash.Resource,
    data_layer: :embedded

  attributes do
    attribute :name, :string do
      public? true
      default ""
    end
  end
end
