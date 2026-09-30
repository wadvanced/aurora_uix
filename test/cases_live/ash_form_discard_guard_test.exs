defmodule Aurora.UixWeb.Test.AshFormDiscardGuardTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Blog.Author

  auix_resource_metadata(:author, ash_resource: Author)

  auix_create_ui do
    edit_layout :author do
      stacked([:name, :email, :bio])
    end
  end

  @spec seed() :: struct()
  defp seed do
    delete_all_blog_data()
    1 |> create_sample_authors() |> List.first()
  end

  @spec request_close(Phoenix.LiveViewTest.View.t()) :: term()
  defp request_close(view) do
    view
    |> with_target("#auix-author-edit-modal [data-phx-component]")
    |> render_click("auix_request_close", %{})
  end

  test "a clean form closes without a prompt", %{conn: conn} do
    author = seed()
    {:ok, view, _html} = live(conn, "/ash-form-discard-guard-authors/#{author.id}/edit")

    request_close(view)

    refute has_element?(view, "#auix-author-edit-modal")
  end

  test "discard changes closes the modal without saving", %{conn: conn} do
    author = seed()
    {:ok, view, _html} = live(conn, "/ash-form-discard-guard-authors/#{author.id}/edit")

    view
    |> form("#auix-author-form", author: %{name: "Changed author"})
    |> render_change()

    request_close(view)
    assert has_element?(view, "#auix-author-discard-confirm-modal")

    view |> element("button[name='auix-discard-changes']") |> render_click()

    refute has_element?(view, "#auix-author-edit-modal")
    assert Ash.get!(Author, author.id).name == author.name
  end
end
