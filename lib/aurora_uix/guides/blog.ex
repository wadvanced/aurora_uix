defmodule Aurora.Uix.Guides.Blog do
  use Ash.Domain
  use Aurora.Uix

  resources do
    resource Aurora.Uix.Guides.Blog.Post
    resource Aurora.Uix.Guides.Blog.Author
    resource Aurora.Uix.Guides.Blog.Category
  end

  auix_resource_metadata(:author, schema: Aurora.Uix.Guides.Blog.Author)
  auix_resource_metadata(:post, schema: Aurora.Uix.Guides.Blog.Post)
  auix_resource_metadata(:category, schema: Aurora.Uix.Guides.Blog.Category)
end
