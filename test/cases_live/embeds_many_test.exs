defmodule Aurora.UixWeb.Test.EmbedsManyTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test
  use Wallaby.Feature

  alias Aurora.Uix.Test.Accounts
  alias Aurora.Uix.Test.Accounts.User
  alias Wallaby.Query
  alias Wallaby.Session

  @new_button Query.css("a[name='auix-new-user']")
  @save_button Query.css("button[name='auix-save-user']")
  @expand_details_button Query.css("details[name^='auix-details-auix-field-user-emails-']")
  @add_embed_button Query.css(
                      "div[name='auix-embeds_many-header_actions'] > div[phx-click='toggle-add-embeds']"
                    )
  @do_add_button Query.css(
                   "div[name='auix-embeds_many-new_entry_actions'] > button[form^='auix-embeds-many-']"
                 )
  @close_add Query.css(
               "div[id*='auix-embeds-many-add-auix-field-user-emails-'][id$='-wrapper'] button.auix-modal-close-button"
             )

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

  feature "Create a new entry without embeds many ", %{session: session} do
    delete_all_accounts_data()

    # Checks if it is well shown
    page = visit(session, "/embeds-many-users")

    page
    |> assert_text("Listing Users")
    |> click_and_wait(@new_button, @save_button)

    session
    |> fill_field(&main_form/1, :given_name, "Paul")
    |> fill_field(&main_form/1, :family_name, "Test")
    |> click_and_wait(@save_button, Query.text("Listing Users"))

    users = Accounts.list_users()

    users
    |> List.first()
    |> Kernel.tap(&assert(&1.given_name == "Paul"))
    |> Kernel.tap(&assert(&1.family_name == "Test"))
    |> Kernel.tap(&assert(&1.profile.online == false))
    |> Kernel.tap(&assert(&1.profile.dark_mode == false))
    |> Kernel.tap(&assert(&1.profile.visibility == :friends_only))
    |> Kernel.tap(&assert(&1.emails == []))
  end

  feature "Create a new entry with embeds many ", %{session: session} do
    delete_all_accounts_data()

    emails = [
      %{email: "is_paul@test.com", name: "Home"},
      %{email: "is_tony@test.com", name: "Work"}
    ]

    # Checks if it is well shown
    session
    |> visit("/embeds-many-users")
    |> assert_text("Listing Users")
    |> click_and_wait(@new_button, @save_button)

    # Main section
    session
    |> fill_field(&main_form/1, :given_name, "Paul")
    |> fill_field(&main_form/1, :family_name, "Test")
    |> fill_field(&profile_form/1, :online, "true")
    |> fill_field(&profile_form/1, :dark_mode, "true")
    |> fill_field(&profile_form/1, :visibility, "private")
    |> click_and_wait(@expand_details_button, @add_embed_button)
    |> click_and_wait(@add_embed_button, @do_add_button)

    # Emails
    emails
    |> Enum.reduce(session, fn email_entry, acc ->
      acc
      |> fill_field(&new_embed_form/1, :email, email_entry.email)
      |> fill_field(&new_embed_form/1, :name, email_entry.name)
      |> click_and_wait(@do_add_button, Query.css("Success!"))
    end)
    |> click_and_wait(@close_add, @add_embed_button)

    # Validate emails
    Enum.with_index(emails, fn email_entry, index ->
      session
      |> validate_field(:email, index, email_entry.email)
      |> validate_field(:name, index, email_entry.name)
    end)

    click_and_wait(session, @save_button, Query.text("Listing Users"))

    users =
      Accounts.list_users()

    users
    |> List.first()
    |> Kernel.tap(&assert(&1.given_name == "Paul"))
    |> Kernel.tap(&assert(&1.family_name == "Test"))
    |> Kernel.tap(&assert(&1.profile.online == true))
    |> Kernel.tap(&assert(&1.profile.dark_mode == true))
    |> Kernel.tap(&assert(&1.profile.visibility == :private))
    |> Kernel.tap(&assert_emails(&1, emails))
  end

  @spec main_form(atom()) :: Query.t()
  defp main_form(field) do
    Query.css("form#auix-user-form [id^='auix-field-user-#{field}-'][id$='--form']")
  end

  @spec profile_form(atom()) :: Query.t()
  defp profile_form(field) do
    Query.css("form#auix-user-form [id^='auix-field-user__profile-#{field}-'][id$='--form']")
  end

  @spec new_embed_form(atom()) :: Query.t()
  defp new_embed_form(field) do
    Query.css(
      "form[id^='auix-embeds-many-auix-field-user-emails-'][id$='-add-form'] [id^='auix-field-user__emails-#{field}-'][id$='--form']"
    )
  end

  @spec emails_form(atom(), integer()) :: Query.t()
  defp emails_form(field, index) do
    Query.css("[name='user[emails][#{index}][#{field}]'")
  end

  @spec validate_field(Session.t(), atom(), integer(), binary()) :: Session.t()
  defp validate_field(session, field, index, value) do
    assert field
           |> emails_form(index)
           |> then(&attr(session, &1, "value")) == value

    session
  end

  @spec fill_field(Session.t(), function(), atom(), term()) :: Session.t()
  defp fill_field(session, query, field, value) do
    field
    |> query.()
    |> Kernel.tap(&click(session, &1))
    |> then(&fill_in(session, &1, with: value))
  end

  @spec click_and_wait(Session.t(), Query.t(), Query.t(), boolean(), integer()) :: Session.t()
  defp click_and_wait(session, clickable, expected, state \\ true, retries \\ 5)
  defp click_and_wait(session, clickable, _state, _expected, 0), do: click(session, clickable)

  defp click_and_wait(session, clickable, expected, state, retries) do
    page = click(session, clickable)

    if has?(page, expected) == state do
      page
    else
      click_and_wait(session, clickable, expected, state, retries - 1)
    end
  end

  @spec assert_emails(map(), list()) :: :boolean
  defp assert_emails(%{emails: emails}, expected) do
    assert expected
           |> Enum.with_index(fn expect, index ->
             email_equals?(Enum.at(emails, index), expect)
           end)
           |> Enum.all?()
  end

  @spec email_equals?(map(), map()) :: boolean()
  defp email_equals?(%{email: email, name: name}, %{email: email, name: name}), do: true
  defp email_equals?(_email, _expected_email), do: false
end
