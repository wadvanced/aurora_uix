defmodule Aurora.UixWeb.Test.AshMany2OneSelectTest do
  @moduledoc """
  Regression test: an Ash `belongs_to` foreign key must render as an editable
  select whose options are loaded from the related (paginated) Ash resource.

  Guards against the `Protocol.Enumerable not implemented for
  Aurora.Ctx.Pagination` crash in `get_select_options/1`.
  """
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Blog.Author
  alias Aurora.Uix.Guides.Blog.Post

  auix_resource_metadata(:author, ash_resource: Author)

  auix_resource_metadata :post, ash_resource: Post do
    field(:author_id, option_label: :name)
  end

  auix_create_ui do
    edit_layout :post do
      inline([:title, :author_id])
    end
  end

  test "belongs_to renders an editable select populated from the related resource",
       %{conn: conn} do
    delete_all_blog_data()
    [author | _] = create_sample_authors(3)

    {:ok, view, _html} = live(conn, "/ash-many2one-select-posts/new")

    assert has_element?(view, "select[name='post[author_id]']")

    assert has_element?(
             view,
             "select[name='post[author_id]'] option[value='#{author.id}']"
           )
  end
end
