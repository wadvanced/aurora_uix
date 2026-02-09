defmodule Aurora.UixWeb.Test.AshEmbedsTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test
  use Phoenix.Component

  alias Aurora.Uix.Guides.Accounts.User
  alias Aurora.Uix.Guides.Blog.Author
  alias Aurora.Uix.Guides.Blog.Post

  alias Aurora.Uix.Integration.Ash.Crud, as: AshCrud
  alias Aurora.Uix.Integration.Ash.CrudSpec, as: AshCrudSpec

  alias Aurora.Uix.Templates.Basic.Helpers, as: BasicHelpers
  auix_resource_metadata(:author, schema: Author, order_by: [:bio])
  auix_resource_metadata(:post, schema: Post, order_by: [published_at: :desc])

  auix_create_ui do
    edit_layout :author do
      stacked([:name, :email, :posts])
    end
  end

  test "Show from list embeds-many", %{conn: conn} do
    test_count = 1
    delete_all_blog_data()

    author =
      1
      |> create_sample_authors()
      |> List.first()

    post =
      test_count
      |> create_sample_posts(%{
        author_id: author.id,
        comment: %{description: "My super comment"},
        tags: [
          %{name: "one"},
          %{name: "two"}
        ]
      })
      |> List.first()

    {:ok, view, _html} = live(conn, "/ash-embeds-posts/#{post.id}/show")

    view
    |> Kernel.tap(
      &assert(has_element?(&1, "div.auix-show-container a[name='auix-edit-post'] button"))
    )
    |> Kernel.tap(
      &assert(
        has_element?(
          &1,
          "div.auix-show-container input[name='title'][value='#{post.title}']"
        )
      )
    )
    |> Kernel.tap(
      &assert(
        has_element?(
          &1,
          "div.auix-show-container input[name='content'][value='#{post.content}']"
        )
      )
    )
    |> Kernel.tap(
      &assert(
        has_element?(
          &1,
          "div.auix-show-container select[name='status'] option[selected=''][value='#{post.status}']"
        )
      )
    )
    |> Kernel.tap(
      &assert(
        has_element?(
          &1,
          "div.auix-show-container input[id^='auix-field-post__comment-description-'][value='#{post.comment.description}']"
        )
      )
    )
    |> Kernel.tap(
      &has_element?(
        &1,
        "details[name^='auix-details-auix-field-post-tags-'] input[name='name'][value='#{Enum.at(post.tags, 0).name}']"
      )
    )
    |> Kernel.tap(
      &has_element?(
        &1,
        "details[name^='auix-details-auix-field-post-tags-'] input[name='name'][value='#{Enum.at(post.tags, 1).name}']"
      )
    )
  end

  test "Test forms creation", %{conn: _conn} do
    delete_all_blog_data()

    data =
      Ash.create!(Post, %{title: "Test post", comment: %{}})

    crud_spec = %AshCrudSpec{
      action: %{name: :update},
      resource: Post,
      auix_action_name: :change_function
    }

    field_name = :comment

    form =
      crud_spec
      |> AshCrud.change(data, :post, %{})
      |> to_form()

    assigns = %{field: form[field_name], inner_block: []}

    assert Phoenix.LiveViewTest.render_component(&inputs_for/1, assigns) =~
             "post[comment]"
  end
end
