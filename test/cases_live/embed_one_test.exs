defmodule Aurora.UixWeb.Test.EmbedOneTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Repo
  alias Aurora.Uix.Test.Accounts
  alias Aurora.Uix.Test.Accounts.User

  auix_resource_metadata(:user, context: Accounts, schema: User)

  auix_create_ui link_prefix: "embed-one-" do
    index_columns(:user, [:full_name, :email, :profile])

    edit_layout :user,
      new_title: "Embed one" do
      stacked do
        inline([:full_name, :email])
        inline([:avatar_url])
        inline([:profile])
      end
    end
  end

  test "Show data", %{conn: conn} do
    test_count = 5
    delete_all_users()
    create_users(test_count)

    {:ok, view, html} = live(conn, "/embed-one-users")
    refute html =~ "Profile"
    assert html =~ "Full name"

    assert(
      view
      |> render()
      |> LazyHTML.from_document()
      |> LazyHTML.query("table.auix-items-table tbody tr")
      |> Enum.count() == test_count
    )
  end

  test "New data", %{conn: conn} do
    delete_all_users()

    {:ok, view, html} = live(conn, "/embed-one-users/new")
    assert html =~ "Embed one"
    assert html =~ "Creates a new <strong>User</strong> record in your database"

    view
    |> form(
      "#auix-user-form",
      %{
        "user" => %{
          "full_name" => "John Test",
          "email" => "thetest@test.com",
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
    |> tap(&assert(&1.full_name == "John Test"))
    |> tap(&assert(&1.email == "thetest@test.com"))
    |> tap(&assert(&1.avatar_url == "https://noexist-avatar.svg"))
    |> tap(&assert(&1.profile.online == true))
    |> tap(&assert(&1.profile.dark_mode == false))
    |> tap(&assert(&1.profile.visibility == :friends_only))
  end

  @spec delete_all_users() :: {integer(), nil | [term()]}
  defp delete_all_users do
    Repo.delete_all(User)
  end

  @spec create_users(non_neg_integer()) :: :ok
  defp create_users(count) do
    Enum.each(
      1..count,
      &Accounts.create_user(%{
        full_name: "John #{&1}",
        email: "john#{&1}@doe.com",
        avatar_url: "https://noexist-avatar-#{&1}.svg",
        profile: %{online: false, dark_mode: false, visibility: :public}
      })
    )
  end
end
