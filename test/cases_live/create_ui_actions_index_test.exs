defmodule Aurora.Uix.Test.Web.CreateUIActionsIndexTest do
  use Aurora.Uix.Test.Web, :aurora_uix_for_test
  use Aurora.Uix.Test.Web.UICase, :phoenix_case
  use Aurora.Uix.CoreComponentsImporter

  import Aurora.Uix.Templates.Basic.RoutingComponents
  import Phoenix.Component, only: [sigil_H: 2]

  alias Aurora.Uix.Test.Inventory
  alias Aurora.Uix.Test.Inventory.Product

  @spec custom_row_action_to_add(map()) :: Rendered.t()
  def custom_row_action_to_add(assigns) do
    ~H"""
      <.auix_link patch={"/#{@auix.link_prefix}#{@auix.source}/#{elem(@auix.row_info, 1).id}/edit"} name={"auix-edit-#{@auix.module}-added"}>Custom Added</.auix_link>
    """
  end

  @spec custom_row_action_to_replace(map()) :: Rendered.t()
  def custom_row_action_to_replace(assigns) do
    ~H"""
      <.auix_link patch={"/#{@auix.link_prefix}#{@auix.source}/#{elem(@auix.row_info, 1).id}/edit"} name={"auix-edit-#{@auix.module}"}>Custom Removed and Added</.auix_link>
    """
  end

  @spec custom_row_action_to_insert(map()) :: Rendered.t()
  def custom_row_action_to_insert(assigns) do
    ~H"""
      <.auix_link patch={"/#{@auix.link_prefix}#{@auix.source}/#{elem(@auix.row_info, 1).id}/edit"} name={"auix-edit-#{@auix.module}-inserted"}>Custom Inserted</.auix_link>
    """
  end

  @spec custom_header_action_added(map()) :: Rendered.t()
  def custom_header_action_added(assigns) do
    ~H"""
    <.auix_link patch={"#{@auix[:index_new_link]}"} name={"auix-new-#{@auix.module}-added"}>
      <.button>Added {@auix.name}</.button>
    </.auix_link>
    """
  end

  @spec custom_header_action_inserted(map()) :: Rendered.t()
  def custom_header_action_inserted(assigns) do
    ~H"""
    <.auix_link patch={"#{@auix[:index_new_link]}"} name={"auix-new-#{@auix.module}-inserted"}>
      <.button>Inserted {@auix.name}</.button>
    </.auix_link>
    """
  end

  @spec custom_header_action_directly_replaced(map()) :: Rendered.t()
  def custom_header_action_directly_replaced(assigns) do
    ~H"""
    <.auix_link patch={"#{@auix[:index_new_link]}"} name={"auix-new-#{@auix.module}"}>
      <.button>New Replaced {@auix.name}</.button>
    </.auix_link>
    """
  end

  @spec custom_footer_action(map()) :: Rendered.t()
  def custom_footer_action(assigns) do
    ~H"""
    <.auix_link patch={"#{@auix[:index_new_link]}"} name={"auix-new-#{@auix.module}-footer"}>
      <.button>Footer {@auix.name}</.button>
    </.auix_link>
    """
  end

  auix_resource_metadata(:product, context: Inventory, schema: Product)

  # When you define a link in a test, add a line to test/support/app_web/router.exs
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui link_prefix: "create-ui-actions-index-" do
    index_columns(:product, [:id, :reference, :name, :description, :quantity_at_hand],
      remove_row_action: :default_row_edit,
      add_row_action: {:custom_row_action_replaced, &__MODULE__.custom_row_action_to_replace/1},
      add_row_action: {:custom_row_action_added, &__MODULE__.custom_row_action_to_add/1},
      insert_row_action: {:custom_row_action_inserted, &__MODULE__.custom_row_action_to_insert/1},
      add_header_action: {:custom_header_action_added, &__MODULE__.custom_header_action_added/1},
      insert_header_action:
        {:custom_header_action_inserted, &__MODULE__.custom_header_action_inserted/1},
      replace_header_action: {:default_new, &__MODULE__.custom_header_action_directly_replaced/1},
      add_footer_action: {:custom_footer_action, &__MODULE__.custom_footer_action/1}
    )

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

  test "Test UI default with schema, context, basic layout", %{conn: conn} do
    {:ok, view, html} = live(conn, "/create-ui-actions-index-products")
    assert html =~ "Listing Products"
    assert html =~ "New Replaced Product"

    assert view
           |> element("a[name='auix-new-product']")
           |> render_click() =~ "New Replaced Product"
  end

  test "Test index row custom actions", %{conn: conn} do
    delete_all_sample_data()
    create_sample_products(5, :test)

    {:ok, _view, html} = live(conn, "/create-ui-actions-index-products")

    # Validate row actions order of elements
    assert html
           |> Floki.find("tr:nth-of-type(1) a[name^='auix-edit-product']")
           |> Enum.map(&Floki.text/1) == [
             "Custom Inserted",
             "Custom Removed and Added",
             "Custom Added"
           ]
  end

  test "Test index header custom actions", %{conn: conn} do
    delete_all_sample_data()
    create_sample_products(5, :test)

    {:ok, _view, html} = live(conn, "/create-ui-actions-index-products")

    # Validate row actions order of elements
    assert html
           |> Floki.find("div[name='auix-index-header-actions'] a[name^='auix-new-product']")
           |> Enum.map(&(&1 |> Floki.text() |> String.trim())) == [
             "Inserted Product",
             "New Replaced Product",
             "Added Product"
           ]
  end

  test "Test index footer custom actions", %{conn: conn} do
    delete_all_sample_data()
    create_sample_products(5, :test)

    {:ok, _view, html} = live(conn, "/create-ui-actions-index-products")

    # Validate row actions order of elements
    assert html
           |> Floki.find("div[name='auix-index-footer-actions'] a[name^='auix-new-product']")
           |> Enum.map(&(&1 |> Floki.text() |> String.trim())) == [
             "Footer Product"
           ]
  end
end
