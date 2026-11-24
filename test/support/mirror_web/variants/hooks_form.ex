defmodule Aurora.UixWeb.Test.Mirror.Variants.HooksForm do
  @moduledoc """
  The `hooks-form` views variant: product form with a custom form handler.

  ## Key Features

  - Declares the product edit layout with an edit handler module and a footer action
  - Declares the product index columns and the show layout
  - Generates the views its scenarios mount

  ## Key Constraints

  - Only for test scenarios
  - Used through `Aurora.UixWeb.Test.MirrorAsh.HooksForm` and
    `Aurora.UixWeb.Test.MirrorCtx.HooksForm`
  """

  use Aurora.Uix.CoreComponentsImporter

  alias Aurora.UixWeb.Test.Mirror.Variants.HooksForm
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
        index_columns(:product, [:id, :reference, :name, :description, :quantity_at_hand])

        show_layout :product do
          inline([:reference, :name, :description])
          inline([:quantity_at_hand, :quantity_initial])
          inline([:list_price, :rrp])
        end

        edit_layout :product,
          edit_handler_module: Aurora.UixWeb.Test.Mirror.Handlers.FormHandlerHook,
          add_footer_action: {:hooks_hide_description, &HooksForm.hooks_footer_action/1} do
          inline([:reference, :name, :description])
          inline([:quantity_at_hand, :quantity_initial])
          inline([:list_price, :rrp])
        end
      end
    end
  end

  @doc false
  @spec hooks_footer_action(map()) :: Rendered.t()
  def hooks_footer_action(assigns) do
    ~H"""
    <button type="button" name="hooks-hide-description" phx-click="hooks_hide_description" phx-target={@auix._myself}>
      Hide description
    </button>
    """
  end
end
