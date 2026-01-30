defmodule Aurora.Uix.Guides.Blog do
  @moduledoc """
  Ash Domain for blog-related resources in guides and examples.

  Defines the blog domain containing posts, authors, and categories for demonstration
  and testing purposes.

  ## Key Features

  - Manages blog posts, authors, and categories
  - Provides Ash Framework domain for guide examples
  - Includes custom domain action for listing categories

  ## Key Constraints

  - Only for guides and test scenarios
  - Not included in production builds
  """
  use Aurora.Uix
  use Ash.Domain

  resources do
    resource Aurora.Uix.Guides.Blog.Post
    resource Aurora.Uix.Guides.Blog.Author

    resource Aurora.Uix.Guides.Blog.Category do
      define :list_categories, action: :read
    end
  end
end
