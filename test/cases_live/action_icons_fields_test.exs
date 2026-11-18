defmodule Aurora.UixWeb.Test.ActionIconsFieldsTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Guides.Accounts
  alias Aurora.Uix.Guides.Accounts.User
  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product
  alias Aurora.Uix.Guides.Inventory.ProductLocation
  alias Aurora.Uix.Guides.Inventory.ProductTransaction

  auix_resource_metadata(:product_location, context: Inventory, schema: ProductLocation)
  auix_resource_metadata(:product_transaction, context: Inventory, schema: ProductTransaction)
  auix_resource_metadata(:product, context: Inventory, schema: Product)
  auix_resource_metadata(:user, context: Accounts, schema: User)

  # When you define a link in a test, add a line to test/support/app_web/routes.ex
  auix_create_ui do
    edit_layout :product do
      stacked([
        :reference,
        :name,
        product_transactions: [
          action_icons: [default_new: "hero-sparkles", default_row_edit: "hero-pencil-square"]
        ]
      ])
    end

    edit_layout :user do
      stacked([
        :given_name,
        emails: [
          action_icons: [
            default_header_enable_add_entry: "hero-sparkles",
            default_remove_entry: "hero-x-mark"
          ]
        ]
      ])
    end
  end

  test "one-to-many actions take the field's action_icons", %{conn: conn} do
    delete_all_inventory_data()

    product_id =
      1
      |> create_sample_products_with_transactions(3, :test)
      |> List.first()
      |> elem(1)
      |> Map.get(:id)

    {:ok, view, _html} = live(conn, "/action-icons-fields-products/#{product_id}/edit")

    assert has_element?(
             view,
             "div[name='auix-one_to_many-product'] [name='auix-one_to_many-header-actions'] a span.hero-sparkles"
           )

    assert has_element?(
             view,
             "div[name='auix-one_to_many-product'] tbody tr:nth-of-type(1) a[name^='auix-edit-'] span.hero-pencil-square"
           )

    assert has_element?(
             view,
             "div[name='auix-one_to_many-product'] tbody tr:nth-of-type(1) a[name^='auix-show-'] span.hero-eye"
           )
  end

  test "embeds-many actions take the field's action_icons", %{conn: conn} do
    delete_all_accounts_data()

    user =
      1
      |> create_sample_users(%{emails: [%{email: "work@test.com", name: "Work"}]})
      |> List.first()

    {:ok, view, _html} = live(conn, "/action-icons-fields-users/#{user.id}/edit")

    assert has_element?(
             view,
             "div[name='auix-embeds_many-header_actions'] > button[title='Add new entry'] span.hero-sparkles"
           )

    assert has_element?(
             view,
             "div[name='auix-embeds_many-header_actions'] > button span.auix-action-label",
             "Add new entry"
           )

    assert has_element?(
             view,
             "div[name='auix-embeds_many-footer_actions'] button span.hero-plus"
           )

    assert has_element?(view, "#auix-remove-button-0 button span.hero-x-mark")
  end
end
