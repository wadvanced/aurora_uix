defmodule Aurora.UixWeb.Test.AshComponentsIndexTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.UixWeb.Test.ComponentHostLive, as: Host

  auix_resource_metadata(:author, ash_resource: Aurora.Uix.Guides.Blog.Author)

  auix_create_ui()

  test "an embedded index on Ash", %{conn: conn} do
    delete_all_blog_data()
    [author | _] = create_sample_authors(2)

    {:ok, view, _html} =
      live_isolated(conn, Host,
        session: %{
          "components" => [%{module: __MODULE__.Author.IndexComponent, id: "a", props: %{}}]
        }
      )

    row = "#a tr[id='a-authors-#{author.id}']"
    assert has_element?(view, row)

    view
    |> element(row <> " td.auix-items-table-action-cell a[name='auix-delete-author']")
    |> render_click()

    assert has_element?(
             view,
             "#auix-host-intents li[data-component='a'][data-intent='deleted'][data-value='#{author.id}']"
           )
  end
end
