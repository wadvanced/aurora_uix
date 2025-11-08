defmodule Aurora.UixWeb.Test.EmbedsManyTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Repo
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
        inline([:emails])
      end
    end
  end

  test "Show data", %{conn: conn} do
    test_count = 5
    delete_all_users()
    create_users(test_count)

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
    delete_all_users()

    {:ok, view, html} = live(conn, "/embeds-one-users/new")
    assert html =~ "Embeds one"
    assert html =~ "Creates a new <strong>User</strong> record in your database"
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
        given_name: "John #{&1}",
        family_name: "john#{&1}@doe.com",
        avatar_url: "https://noexist-avatar-#{&1}.svg",
        profile: %{online: false, dark_mode: false, visibility: :public}
      })
    )
  end
end
