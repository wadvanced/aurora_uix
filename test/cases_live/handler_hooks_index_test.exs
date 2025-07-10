defmodule Aurora.Uix.Test.Web.HandlerHooksIndexTest do
  use Aurora.Uix.Test.Web, :aurora_uix_for_test
  use Aurora.Uix.Test.Web.UICase, :phoenix_case

  alias Aurora.Uix.Test.Inventory
  alias Aurora.Uix.Test.Inventory.Product

  auix_resource_metadata(:product, context: Inventory, schema: Product)

  # When you define a link in a test, add a line to test/support/app_web/router.exs
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui link_prefix: "handler-hooks-index-" do
    index_columns(:product, [:id, :reference, :name, :description, :quantity_at_hand])

    edit_layout :product do
      inline([:reference, :name, :description])
      inline([:quantity_at_hand, :quantity_initial])
      inline([:list_price, :rrp])
    end

    show_layout :product do
      inline([:reference, :name, :description])
      inline([:quantity_at_hand, :quantity_initial])
      inline([:list_price, :rrp])
    end
  end

  test "Test index hooks", %{conn: conn} do
    {:ok, _view, _html} = live(conn, "/handler-hooks-index-products")
  end
end

defmodule Aurora.Uix.Test.Web.IndexHandler do
end
