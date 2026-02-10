defmodule Aurora.UixWeb.Guides.AshOverview do
  @moduledoc """
  Demonstrates Aurora UIX integration with Ash Framework resources.

  This module showcases how to configure UI components for Ash resources including
  blog posts, authors, categories, and tags. It defines custom layouts for index,
  show, and edit views using Aurora UIX's declarative DSL.

  ## Key Features
  - Resource metadata configuration for Ash resources
  - Custom index column definitions
  - Declarative show and edit layouts with grouped fields
  - Integration between Aurora UIX and Ash Framework

  ## Key Constraints
  - Requires Aurora.Uix behaviour implementation
  - Depends on Blog domain resources (Author, Post, Category, Tag)
  - Layout definitions must follow auix_create_ui DSL syntax
  """

  use Aurora.Uix

  alias Aurora.Uix.Guides.Blog.Author
  alias Aurora.Uix.Guides.Blog.Category
  alias Aurora.Uix.Guides.Blog.Post
  alias Aurora.Uix.Guides.Blog.Tag

  auix_resource_metadata(:author, ash_resource: Author)
  auix_resource_metadata(:post, ash_resource: Post)
  auix_resource_metadata(:category, ash_resource: Category)
  auix_resource_metadata(:tag, ash_resource: Tag)

  auix_create_ui do
    index_columns(:post, [:title, :author, :status])

    show_layout :post do
      stacked do
        inline([:status])
        inline([:title, :author])
        inline([:comment])
      end
    end

    edit_layout :post do
      stacked do
        inline([:title])
        inline([:author])
        inline([:comment])

        group "details" do
          inline([:status, :published_at])
        end

        inline([:tags])
      end
    end
  end
end
