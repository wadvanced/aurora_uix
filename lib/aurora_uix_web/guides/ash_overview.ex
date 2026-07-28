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
  alias Aurora.Uix.Guides.Blog.AuthorProfile
  alias Aurora.Uix.Guides.Blog.Category
  alias Aurora.Uix.Guides.Blog.Comment
  alias Aurora.Uix.Guides.Blog.Post
  alias Aurora.Uix.Guides.Blog.Tag
  alias Aurora.Uix.Guides.Blog.Topic

  auix_resource_metadata(:author__author_profile, ash_resource: AuthorProfile)

  auix_resource_metadata(:author, ash_resource: Author) do
    field :bio, html_type: :textarea
  end

  auix_resource_metadata(:category, ash_resource: Category)

  auix_resource_metadata(:post__comment, ash_resource: Comment) do
    field :description, html_type: :textarea
  end

  auix_resource_metadata(:topics, ash_resource: Topic)

  auix_resource_metadata(:post, ash_resource: Post, order_by: :title) do
    field :topics, label: "Topics"
  end

  auix_resource_metadata(:tag, ash_resource: Tag)

  auix_create_ui do
    show_layout :author do
      stacked([:name, :email, :bio])

      group "Author profile" do
        inline([:author_profile])
      end
    end

    edit_layout :author do
      inline([:name, :email, :bio])

      group "Author profile" do
        inline([:author_profile])
      end
    end

    index_columns(:post, [:title, :author, :status])

    show_layout :post do
      stacked([:status, :title, :author, :comment, :summary])

      group "markers" do
        inline([:tags])
        inline([:topics])
      end
    end

    edit_layout :post do
      stacked do
        inline([:title])
        inline([:author])
        inline([:comment])

        group "details" do
          stacked([:status, :published_at])
        end

        group "markers" do
          inline([:tags])
          inline([:topics])
        end

        inline([:summary])
      end
    end
  end
end
