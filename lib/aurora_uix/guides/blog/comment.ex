defmodule Aurora.Uix.Guides.Blog.Comment do
  use Ash.Resource,
    data_layer: :embedded

  attributes do
    attribute :description, :string, public?: true
  end
end
