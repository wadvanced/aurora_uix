defmodule Aurora.UixWeb.Test.EmbedsManyTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Test.Accounts
  alias Aurora.Uix.Test.Accounts.User

  auix_resource_metadata(:user, context: Accounts, schema: User)

  auix_create_ui link_prefix: "embeds-many-" do
    index_columns(:user, [:given_name, :family_name, :emails])

    edit_layout :user,
      new_title: "Embeds many" do
      stacked do
        inline([:given_name, :family_name])
        inline([:avatar_url])
        stacked([:profile, :emails])
      end
    end
  end

  test "Show data", %{conn: conn} do
    test_count = 5
    delete_all_accounts_data()
    create_sample_users(test_count)

    {:ok, view, html} = live(conn, "/embeds-many-users")
    refute html =~ "Emails"
    assert html =~ "Given name"

    assert(
      view
      |> render()
      |> LazyHTML.from_document()
      |> LazyHTML.query("table.auix-items-table tbody tr")
      |> Enum.count() == test_count
    )
  end

  test "New data", %{conn: conn} do
    delete_all_accounts_data()

    {:ok, _view, html} = live(conn, "/embeds-many-users/new")
    assert html =~ "Embeds many"
    assert html =~ "Creates a new <strong>User</strong> record in your database"
  end
end
