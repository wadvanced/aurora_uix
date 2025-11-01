defmodule Aurora.UixWeb.Test.EmbedOneTest do
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test
  use Aurora.UixWeb.UICase, :phoenix_case

  alias Aurora.Uix.Test.Accounts
  alias Aurora.Uix.Test.Accounts.User

  auix_resource_metadata(:user, context: Accounts, schema: User)

  auix_create_ui link_prefix: "embed-one-" do
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
    live(conn, "/embed-one-users")
  end
end
