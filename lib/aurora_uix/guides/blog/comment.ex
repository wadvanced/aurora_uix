defmodule Aurora.Uix.Guides.Blog.Comment do
  @moduledoc """
  Example embedded resource for guide demonstrations.

  Simple comment structure used in blog guides to demonstrate embedded resources
  with Ash Framework.
  """
  use Ash.Resource,
    data_layer: :embedded

  attributes do
    attribute :description, :string, public?: true
  end
end
