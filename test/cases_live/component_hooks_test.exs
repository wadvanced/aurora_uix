defmodule Aurora.UixWeb.Test.ComponentHooksTest do
  use Aurora.UixWeb.Test.UICase, :phoenix_case
  use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test

  alias Aurora.Uix.Events
  alias Aurora.Uix.Guides.Inventory
  alias Aurora.Uix.Guides.Inventory.Product
  alias Aurora.Uix.Repo
  alias Aurora.UixWeb.Test.ComponentHooksTest, as: T
  alias Aurora.UixWeb.Test.ComponentHostLive, as: Host

  alias T.Product.IndexComponent, as: C

  auix_resource_metadata(:product, context: Inventory, schema: Product)

  auix_create_ui do
    index_columns(:product, [:reference, :name], pagination_items_per_page: 5)
  end

  setup do
    delete_all_inventory_data()
    create_sample_products(3, :test)
    :ok
  end

  test "the hook forwards events to every instance", %{conn: conn} do
    {:ok, view, _html} =
      live_isolated(conn, Host,
        session: %{
          "hooks" => true,
          "components" => [
            %{module: C, id: "a", props: %{}},
            %{module: C, id: "b", props: %{where: [{:reference, :lt, "item_test-2"}]}}
          ]
        }
      )

    added = publish_created()
    _ = :sys.get_state(view.pid)

    assert has_element?(view, "#a tr[id='a-products-#{added.id}']")
    assert has_element?(view, "#b tr[id='b-products-#{added.id}']")
  end

  test "without the hook nothing is forwarded", %{conn: conn} do
    {:ok, view, _html} =
      live_isolated(conn, Host, session: %{"components" => [%{module: C, id: "a", props: %{}}]})

    added = publish_created()
    _ = :sys.get_state(view.pid)

    refute has_element?(view, "#a tr[id='a-products-#{added.id}']")
  end

  test "other messages reach the host", %{conn: conn} do
    {:ok, view, _html} =
      live_isolated(conn, Host,
        session: %{"hooks" => true, "components" => [%{module: C, id: "a", props: %{}}]}
      )

    send(view.pid, {:other, "x"})

    assert has_element?(view, "#auix-host-other li[data-message='x']")
  end

  @spec publish_created() :: Product.t()
  defp publish_created do
    {:ok, added} = Repo.insert(%Product{reference: "item_test-0", name: "Added"})
    Events.created(added)
    added
  end
end
