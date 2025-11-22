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

  test "Show list embeds-many", %{conn: conn} do
    test_count = 5
    delete_all_accounts_data()

    create_sample_users(test_count)

    {:ok, _view, html} = live(conn, "/embeds-many-users")
    refute html =~ "Emails"
    assert html =~ "Given Name"

    assert(
      html
      |> LazyHTML.from_document()
      |> LazyHTML.query("table.auix-items-table tbody tr")
      |> Enum.count() == test_count
    )
  end

  test "Show from list embeds-many", %{conn: conn} do
    test_count = 1
    delete_all_accounts_data()

    user =
      test_count
      |> create_sample_users(%{
        profile: %{online: true, dark_mode: true, visibility: :public},
        emails: [
          %{email: "is_paul@test.com", name: "Work"},
          %{email: "personal_paul@test.com", name: "Home"}
        ]
      })
      |> List.first()

    {:ok, view, _html} = live(conn, "/embeds-many-users/#{user.id}")

    view
    |> Kernel.tap(
      &assert(has_element?(&1, "div.auix-show-container a[name='auix-edit-user'] button"))
    )
    |> Kernel.tap(
      &assert(
        has_element?(
          &1,
          "div.auix-show-container input[name='given_name'][value='#{user.given_name}']"
        )
      )
    )
    |> Kernel.tap(
      &assert(
        has_element?(
          &1,
          "div.auix-show-container input[name='avatar_url'][value='#{user.avatar_url}']"
        )
      )
    )
    |> Kernel.tap(
      &assert(
        has_element?(
          &1,
          "div.auix-show-container input[id^='auix-field-user__profile-online-'][value='#{user.profile.online}']"
        )
      )
    )
    |> Kernel.tap(
      &assert(
        has_element?(
          &1,
          "div.auix-show-container input[id^='auix-field-user__profile-dark_mode-'][value='#{user.profile.dark_mode}']"
        )
      )
    )
    |> Kernel.tap(
      &assert(
        has_element?(
          &1,
          "div.auix-show-container select[id^='auix-field-user__profile-visibility-'] option[selected][value='#{user.profile.visibility}']"
        )
      )
    )
    |> Kernel.tap(
      &has_element?(
        &1,
        "details[name^='auix-details-auix-field-user-emails-'] input[name='email'][value='#{Enum.at(user.emails, 0).email}']"
      )
    )
    |> Kernel.tap(
      &has_element?(
        &1,
        "details[name^='auix-details-auix-field-user-emails-'] input[name='email'][value='#{Enum.at(user.emails, 1).email}']"
      )
    )
    |> Kernel.tap(
      &has_element?(
        &1,
        "details[name^='auix-details-auix-field-user-emails-'] input[name='name'][value='#{Enum.at(user.emails, 0).name}']"
      )
    )
    |> Kernel.tap(
      &has_element?(
        &1,
        "details[name^='auix-details-auix-field-user-emails-'] input[name='name'][value='#{Enum.at(user.emails, 1).name}']"
      )
    )
  end
end
