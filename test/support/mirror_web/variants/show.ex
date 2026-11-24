defmodule Aurora.UixWeb.Test.Mirror.Variants.Show do
  @moduledoc """
  The `show` views variant: a product show layout with a group, sections and custom actions.

  ## Key Features

  - Declares a product show layout with a group and a Prices and a Dimensions section
  - Replaces the default edit header action and adds a footer action to the show layout
  - Declares a product index and edit layout

  ## Key Constraints

  - Only for test scenarios
  - Used through `Aurora.UixWeb.Test.MirrorAsh.Show` and `Aurora.UixWeb.Test.MirrorCtx.Show`
  """

  use Aurora.Uix.CoreComponentsImporter

  import Aurora.Uix.Templates.Basic.RoutingComponents

  alias Aurora.UixWeb.Test.Mirror.Variants.Show
  alias Phoenix.LiveView.Rendered

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

      auix_create_ui do
        index_columns(:product, [:reference, :name, :quantity_initial], order_by: :reference)

        edit_layout :product, [] do
          stacked do
            inline([:reference, :name, :description])
            inline([:quantity_initial, :quantity_at_hand])
          end
        end

        show_layout :product,
          replace_header_action: {:default_edit, &Show.custom_header_action/1},
          add_footer_action: {:custom_back_action, &Show.custom_back_footer_action/1} do
          inline([:reference, :name, :description])

          group "Quantities" do
            inline([:quantity_at_hand, :quantity_initial])
          end

          sections do
            section "Prices" do
              stacked([:list_price, :rrp])
            end

            section "Dimensions" do
              inline([:width, :height, :length])
            end
          end
        end
      end
    end
  end

  @doc false
  @spec custom_header_action(map()) :: Rendered.t()
  def custom_header_action(assigns) do
    ~H"""
    <.auix_link patch={"/#{@auix.uri_path}/#{@auix.entity.id}/show-edit"} name={"auix-edit-#{@auix.module}"}>
      <.button>Edit Custom {@auix.name}</.button>
    </.auix_link>
    """
  end

  @doc false
  @spec custom_back_footer_action(map()) :: Rendered.t()
  def custom_back_footer_action(assigns) do
    ~H"""
    <div name="auix-show-navigate-back">
      <.auix_back>Back Custom to {@auix.title}</.auix_back>
    </div>
    """
  end
end
