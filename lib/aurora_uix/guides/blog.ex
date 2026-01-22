defmodule Aurora.Uix.Guides.Blog do
  @moduledoc """
  Ash Domain for blog-related resources in guides and examples.

  This module defines the blog domain containing posts, authors, and categories.
  It is excluded from package builds and intended for use in test and development
  environments only.

  ## Key Features
  - Manages blog posts, authors, and categories
  - Provides Ash Framework domain for guide examples

  ## Key Constraints
  - Only for guides and test scenarios
  - Not included in production builds
  """
  use Aurora.Uix
  use Ash.Domain

  resources do
    resource Aurora.Uix.Guides.Blog.Post
    resource Aurora.Uix.Guides.Blog.Author
    resource Aurora.Uix.Guides.Blog.Category
  end
end
