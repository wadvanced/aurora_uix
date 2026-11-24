defmodule Aurora.UixWeb.Test.Mirror.Variants.ManyToManyActions do
  @moduledoc """
  The `many-to-many-actions` views variant: label, header and footer actions of a many-to-many
  group, replaced and added.

  ## Key Features

  - Replaces the toggle all of the suppliers group with a custom label action
  - Adds a custom header and a custom footer action to the group
  - Declares no option label, so the options take the label of the related resource

  ## Key Constraints

  - Only for test scenarios
  - Used through `Aurora.UixWeb.Test.MirrorAsh.ManyToManyActions` and
    `Aurora.UixWeb.Test.MirrorCtx.ManyToManyActions`
  """

  use Aurora.Uix.CoreComponentsImporter

  alias Aurora.UixWeb.Test.Mirror.Variants.ManyToManyActions
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
      mirror_resource(:supplier)

      auix_create_ui do
        edit_layout :product do
          stacked([
            :reference,
            :name,
            suppliers: [
              remove_label_action: :default_toggle_all,
              add_label_action: {:custom_label, &ManyToManyActions.custom_label_action/1},
              add_header_action: {:custom_header, &ManyToManyActions.custom_header_action/1},
              add_footer_action: {:custom_footer, &ManyToManyActions.custom_footer_action/1}
            ]
          ])
        end
      end
    end
  end

  @doc false
  @spec custom_label_action(map()) :: Rendered.t()
  def custom_label_action(assigns) do
    ~H"""
      <.button type="button" name={"auix-custom-label-#{@field.key}"}>Custom label</.button>
    """
  end

  @doc false
  @spec custom_header_action(map()) :: Rendered.t()
  def custom_header_action(assigns) do
    ~H"""
      <.button type="button" name={"auix-custom-header-#{@field.key}"}>Custom header</.button>
    """
  end

  @doc false
  @spec custom_footer_action(map()) :: Rendered.t()
  def custom_footer_action(assigns) do
    ~H"""
      <.button type="button" name={"auix-custom-footer-#{@field.key}"}>Custom footer</.button>
    """
  end
end
