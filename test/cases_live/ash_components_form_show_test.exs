defmodule Aurora.UixWeb.Test.AshComponentsFormShowTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.UixWeb.Test.ComponentHostLive, as: Host

  auix_resource_metadata(:author, ash_resource: Aurora.Uix.Guides.Blog.Author)

  auix_create_ui()

  test "embedded form and show on Ash", %{conn: conn} do
    delete_all_blog_data()
    [author] = create_sample_authors(1)

    {:ok, view, _html} =
      mount_components(conn, [
        %{module: __MODULE__.Author.FormComponent, id: "f1", props: %{action: :new}}
      ])

    view
    |> form("#auix-author-form", author: %{name: "Ada", email: "ada@example.com"})
    |> render_submit()

    assert has_element?(view, "#auix-host-intents li[data-intent='saved']")

    {:ok, show, _html} =
      mount_components(conn, [
        %{module: __MODULE__.Author.ShowComponent, id: "s1", props: %{entity_id: author.id}}
      ])

    assert has_element?(
             show,
             "div.auix-show-container input[name='name'][value='#{author.name}']"
           )
  end

  @spec mount_components(Plug.Conn.t(), list(map())) :: tuple()
  defp mount_components(conn, components),
    do: live_isolated(conn, Host, session: %{"components" => components})
end
