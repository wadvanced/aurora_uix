defmodule Aurora.UixWeb.Test.AshDefaultLayoutTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  # alias Aurora.Uix.Guides.Blog
  alias Aurora.Uix.Guides.Blog.Author
  # alias Aurora.Uix.Guides.Blog.Category
  # alias Aurora.Uix.Guides.Blog.Post

  auix_resource_metadata(:author, schema: Author)
end
