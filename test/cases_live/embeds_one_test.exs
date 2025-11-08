defmodule Aurora.UixWeb.Test.EmbedsOneTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Test.Accounts
  alias Aurora.Uix.Test.Accounts.User

  auix_resource_metadata(:user, context: Accounts, schema: User)

  auix_create_ui link_prefix: "embeds-one-" do
    index_columns(:user, [:given_name, :family_name, :profile])

    edit_layout :user,
      new_title: "Embeds one" do
      stacked do
        inline([:given_name, :family_name])
        inline([:avatar_url])
        inline([:profile])
      end
    end
  end

  test "Show data", %{conn: conn} do
    test_count = 5
    delete_all_accounts_data()
    create_sample_users(test_count)

    {:ok, view, html} = live(conn, "/embeds-one-users")
    refute html =~ "Profile"
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

    {:ok, view, html} = live(conn, "/embeds-one-users/new")
    assert html =~ "Embeds one"
    assert html =~ "Creates a new <strong>User</strong> record in your database"

    view
    |> form(
      "#auix-user-form",
      %{
        "user" => %{
          "given_name" => "John Test",
          "family_name" => "thetest@test.com",
          "avatar_url" => "https://noexist-avatar.svg",
          "profile" => %{
            "online" => true,
            "dark_mode" => false,
            "visibility" => "friends_only"
          }
        }
      }
    )
    |> render_submit()

    users = Accounts.list_users()

    users
    |> List.first()
    |> tap(&assert(&1.given_name == "John Test"))
    |> tap(&assert(&1.family_name == "thetest@test.com"))
    |> tap(&assert(&1.avatar_url == "https://noexist-avatar.svg"))
    |> tap(&assert(&1.profile.online == true))
    |> tap(&assert(&1.profile.dark_mode == false))
    |> tap(&assert(&1.profile.visibility == :friends_only))
  end
end
