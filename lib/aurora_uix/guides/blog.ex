defmodule Aurora.Uix.Guides.Blog do
  use Ash.Domain
  use Aurora.Uix

  resources do
    resource Aurora.Uix.Guides.Blog.Post
    resource Aurora.Uix.Guides.Blog.Author
    resource Aurora.Uix.Guides.Blog.Category
  end
end
