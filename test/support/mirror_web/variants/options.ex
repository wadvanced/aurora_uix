defmodule Aurora.UixWeb.Test.Mirror.Variants.Options do
  @moduledoc """
  The `options` views variant: layout titles and subtitles, a layout preload, a resource preload
  and a resource `where`.

  ## Key Features

  - Sets the titles and subtitles of the product index, form and show layouts
  - Marks, in each index row, whether the relationship of the row is loaded
  - Declares the product transactions index with a layout preload and the product locations
    resource with a preload and a `where`

  ## Key Constraints

  - Only for test scenarios
  - Used through `Aurora.UixWeb.Test.MirrorAsh.Options` and `Aurora.UixWeb.Test.MirrorCtx.Options`
  """

  use Phoenix.Component

  alias Aurora.UixWeb.Test.Mirror.Variants.Options

  @doc """
  Declares the variant's resources and UI in the caller.

  ## Parameters
  - `opts` (keyword()) - `backend: :ash | :ctx`.

  ## Returns
  Macro.t() - The quoted variant.
  """
  @spec __using__(keyword()) :: Macro.t()
  defmacro __using__(opts) do
    quote do
      use Aurora.UixWeb.Test.Mirror, unquote(opts)

      mirror_resource(:product)

      mirror_resource :product_transaction do
        field(:type, index_renderer: &Options.product_marker/1)
      end

      mirror_resource :product_location do
        preload([:products])
        where([{:reference, :between, "test-reference-test-1", "test-reference-test-2"}])

        field(:name,
          index_renderer: &Options.products_marker/1
        )
      end

      mirror_resource :product_barcode do
        field(:code, index_renderer: &Options.product_marker/1)
      end

      auix_create_ui do
        index_columns(:product, [:id, :reference, :name, :description, :quantity_at_hand],
          page_title: "The Products Listing"
        )

        edit_layout :product,
          new_title: "Add a Product",
          new_subtitle: &Options.new_subtitle/1,
          edit_title: &Options.edit_title/1,
          edit_subtitle: "Entries are validated before saving" do
          inline([:reference, :name, :description])
          inline([:quantity_at_hand, :quantity_initial])
          inline([:list_price, :rrp])
        end

        show_layout :product,
          page_title: &Options.page_title/1,
          page_subtitle: nil do
          inline([:reference, :name, :description])
          inline([:quantity_at_hand, :quantity_initial])
          inline([:list_price, :rrp])
        end

        index_columns(:product_transaction, [:type, :quantity], preload: [:product])
        index_columns(:product_location, [:reference, :name])
        index_columns(:product_barcode, [:code, :symbology])
      end
    end
  end

  @doc false
  @spec page_title(map()) :: term()
  def page_title(assigns) do
    ~H"Details for {@auix.name}"
  end

  @doc false
  @spec edit_title(map()) :: term()
  def edit_title(%{auix: %{form: _form}} = assigns),
    do: ~H"Modify {@auix.name}: #{@auix.form[:reference].value} "

  def edit_title(%{auix: %{entity: nil}} = assigns), do: ~H"Modify {@auix.name}"

  def edit_title(%{auix: %{entity: _entity}} = assigns),
    do: ~H"Modify {@auix.name}: {@auix.entity.reference}"

  @doc false
  @spec new_subtitle(map()) :: term()
  def new_subtitle(assigns),
    do: ~H"Please fill <strong>{@auix.name}'s</strong> values properly"

  @doc false
  @spec product_marker(map()) :: Phoenix.LiveView.Rendered.t()
  def product_marker(assigns) do
    assigns = assign(assigns, :marker, marker(assigns.entity.product))

    ~H"""
    <span class="auix-product-marker">{@marker}</span>
    """
  end

  @doc false
  @spec products_marker(map()) :: Phoenix.LiveView.Rendered.t()
  def products_marker(assigns) do
    assigns = assign(assigns, :marker, marker(assigns.entity.products))

    ~H"""
    <span class="auix-products-marker">{@marker}</span>
    """
  end

  @spec marker(term()) :: binary()
  defp marker(%Ecto.Association.NotLoaded{}), do: "NOT_LOADED"
  defp marker(%Ash.NotLoaded{}), do: "NOT_LOADED"
  defp marker(_loaded), do: "LOADED"
end
