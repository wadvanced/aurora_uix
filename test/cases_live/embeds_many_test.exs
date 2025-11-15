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
    assert html =~ "Given Name"

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

    {:ok, view, html} = live(conn, "/embeds-many-users/new")
    assert html =~ "Embeds many"
    assert html =~ "Creates a new <strong>User</strong> record in your database"

    view
    |> form("#auix-user-form", %{
      user: %{
        given_name: "John",
        family_name: "DoeTest",
        profile: %{online: false, visibility: :private}
      }
    })
    |> render_change()

    # Checks the details expand
    assert_details_state(view, false)

    view
    |> element("details[phx-click='toggle-details-state']")
    |> render_click()

    assert_details_state(view, true)

    # Checks the add embeds state
    assert_add_embeds_state(view, false)

    view
    |> element("button[phx-click='toggle-add-embeds']")
    |> render_click()

    assert_add_embeds_state(view, true)

    # Add a couple of emails

    view
    |> render()
    |> LazyHTML.from_document()
    |> LazyHTML.query("[id^='auix-embeds-many-add-auix-field-user-emails-'][id$='-wrapper']")

    # |> LazyHTML.child_nodes()
    # |> IO.inspect(label: "********* found")

    # view
    # |> form("form[id^='auix-embeds-many-auix-field-user-emails-'][id$='-add-form']", %{
    #   "email" => "thedoe@test.com",
    #   "name" => "home"
    # })
    # |> render_change()
    #
    # assert view
    #        |> element(
    #          "button[form^='auix-embeds-many-auix-field-user-emails-'][form$='-add-form']"
    #        )
    #        |> render_click =~ "Entry added successfully"
  end

  @spec assert_details_state(map(), boolean()) :: boolean()
  defp assert_details_state(view, state) do
    assert view
           |> render()
           |> LazyHTML.from_document()
           |> LazyHTML.query("details[phx-click='toggle-details-state']")
           |> LazyHTML.attribute("open")
           |> Kernel.==([""]) == state
  end

  @spec assert_add_embeds_state(map(), boolean()) :: boolean()
  defp assert_add_embeds_state(view, state) do
    assert view
           |> render()
           |> LazyHTML.from_document()
           |> LazyHTML.query(
             "[id^='auix-embeds-many-add-auix-field-user-emails-'][id$='-wrapper']"
           )
           |> LazyHTML.attributes()
           |> Kernel.!=([]) == state
  end
end
