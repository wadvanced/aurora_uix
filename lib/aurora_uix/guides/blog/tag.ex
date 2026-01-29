defmodule Aurora.Uix.Guides.Blog.Tag do
  use Ash.Resource,
    data_layer: :embedded

  attributes do
    attribute :name, :string, public?: true
  end
end
