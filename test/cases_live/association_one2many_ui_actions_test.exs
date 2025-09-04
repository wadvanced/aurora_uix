defmodule Aurora.Uix.Test.Web.AssociationOne2ManyUIActionsTest do
  use Aurora.Uix.Test.Web, :aurora_uix_for_test
  use Aurora.Uix.Test.Web.UICase, :phoenix_case
  use Aurora.Uix.CoreComponentsImporter

  import Aurora.Uix.Templates.Basic.RoutingComponents
  import Phoenix.Component, only: [sigil_H: 2]

  alias Aurora.Uix.Test.Inventory
  alias Aurora.Uix.Test.Inventory.Product
  alias Aurora.Uix.Test.Inventory.ProductLocation
  alias Aurora.Uix.Test.Inventory.ProductTransaction

  @spec custom_new_child(map()) :: Rendered.t()
  def custom_new_child(assigns) do
    ~H"""
      <.auix_link :if={@auix[:layout_type] == :form && @auix.entity.id != nil}
          navigate={"#{@auix.association.related_parsed_opts.index_new_link}?related_key=#{@auix.association.related_key}&parent_id=#{Map.get(@auix.entity, @auix.association.owner_key)}"}
          name={"auix-new-#{@auix.association.parsed_opts.module}__#{@field.key}-#{@auix.layout_type}"}>
        custom new
      </.auix_link>
    """
  end

  @spec custom_edit_row_action(map()) :: Rendered.t()
  def custom_edit_row_action(assigns) do
    ~H"""
      <.auix_link navigate={"/#{@auix.association.related_parsed_opts.link_prefix}#{@auix.association.related_parsed_opts.source}/#{elem(@auix.row_info, 0)}"}
        name={"auix-edit-#{@auix.association.parsed_opts.module}__#{@auix.association.related_parsed_opts.module}-#{elem(@auix.row_info, 0)}"}>
          Custom edit
      </.auix_link>
    """
  end

  @spec custom_footer_action(map()) :: Rendered.t()
  def custom_footer_action(assigns) do
    ~H"""
      <.auix_link :if={@auix.entity.id != nil}
          navigate={"#{@auix.association.related_parsed_opts.index_new_link}?related_key=#{@auix.association.related_key}&parent_id=#{Map.get(@auix.entity, @auix.association.owner_key)}"}
          name={"auix-new-#{@auix.association.parsed_opts.module}__#{@field.key}-#{@auix.layout_type}"}>
        Custom footer
      </.auix_link>
    """
  end

  @spec custom_footer_second_action(map()) :: Rendered.t()
  def custom_footer_second_action(assigns) do
    ~H"""
      <.auix_link :if={@auix.entity.id != nil}
          navigate={"#{@auix.association.related_parsed_opts.index_new_link}?related_key=#{@auix.association.related_key}&parent_id=#{Map.get(@auix.entity, @auix.association.owner_key)}"}
          name={"auix-new-#{@auix.association.parsed_opts.module}__#{@field.key}-#{@auix.layout_type}"}>
        Custom footer second
      </.auix_link>
    """
  end

  auix_resource_metadata(:product_location, context: Inventory, schema: ProductLocation)
  auix_resource_metadata(:product_transaction, context: Inventory, schema: ProductTransaction)

  auix_resource_metadata(:product, context: Inventory, schema: Product)

  # When you define a link in a test, add a line to test/support/app_web/router.exs
  # See section `Including cases_live tests in the test server` in the README.md file.
  auix_create_ui(link_prefix: "association-one_to_many-actions-") do
    edit_layout :product do
      stacked([
        :reference,
        :name,
        :description,
        :quantity_initial,
        product_transactions: [
          add_header_action: {:custom_action, &__MODULE__.custom_new_child/1},
          replace_row_action: {:default_row_edit, &__MODULE__.custom_edit_row_action/1},
          add_footer_action:
            {:custom_footer_second_action, &__MODULE__.custom_footer_second_action/1},
          insert_footer_action: {:custom_footer_action, &__MODULE__.custom_footer_action/1}
        ]
      ])
    end
  end

  test "Test header actions", %{conn: conn} do
    delete_all_sample_data()
    # Create sample data with 1 product
    product_id =
      3
      |> create_sample_products(:test)
      |> Map.get("id_test-1")
      |> Map.get(:id)

    {:ok, _view, html} =
      live(conn, "/association-one_to_many-actions-products/#{product_id}/edit")

    assert html
           |> LazyHTML.from_document()
           |> LazyHTML.query(
             "div[name='auix-one_to_many-product'] [name='auix-one_to_many-header-actions'] a"
           )
           |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim())) == [
             "",
             "custom new"
           ]
  end

  test "Test row actions", %{conn: conn} do
    delete_all_sample_data()
    # Create sample data with 1 product
    product_id =
      1
      |> create_sample_products_with_transactions(3, :test)
      |> List.first()
      |> elem(1)
      |> Map.get(:id)

    {:ok, _view, html} =
      live(conn, "/association-one_to_many-actions-products/#{product_id}/edit")

    assert html
           |> LazyHTML.from_document()
           |> LazyHTML.query("div[name='auix-one_to_many-product'] tbody tr:nth-of-type(1) a")
           |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim())) == [
             "",
             "Custom edit",
             ""
           ]
  end

  test "Test footer actions", %{conn: conn} do
    delete_all_sample_data()
    # Create sample data with 1 product
    product_id =
      3
      |> create_sample_products(:test)
      |> Map.get("id_test-1")
      |> Map.get(:id)

    {:ok, _view, html} =
      live(conn, "/association-one_to_many-actions-products/#{product_id}/edit")

    assert html
           |> LazyHTML.from_document()
           |> LazyHTML.query(
             "div[name='auix-one_to_many-product'] [name='auix-one_to_many-footer_actions'] a"
           )
           |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim())) == [
             "Custom footer",
             "Custom footer second"
           ]
  end
end
