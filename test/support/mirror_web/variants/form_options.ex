defmodule Aurora.UixWeb.Test.Mirror.Variants.FormOptions do
  @moduledoc """
  The `form-options` views variant: form and show options — actions, action icons, the discard
  guard switch, multi-select actions and an index handler that puts flashes.

  ## Key Features

  - Declares a product form with an added header action, an inserted footer action, a save icon
    and the unsaved-changes guard disabled
  - Replaces the label action of the `labels` multi-select and adds its header and footer actions
  - Declares a product show view with a back icon
  - Lists the products through a handler that puts a success and a warning flash

  ## Key Constraints

  - Only for test scenarios
  - Used through `Aurora.UixWeb.Test.MirrorAsh.FormOptions` and
    `Aurora.UixWeb.Test.MirrorCtx.FormOptions`
  """

  use Aurora.Uix.CoreComponentsImporter

  alias Aurora.UixWeb.Test.Mirror.Variants.FormOptions
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
        index_columns(:product, [:reference, :name],
          handler_module: Aurora.UixWeb.Test.Mirror.Handlers.FlashKindsHandlerHook
        )

        edit_layout :product,
          unsaved_changes_guard_disabled?: true,
          add_header_action: {:custom_header, &FormOptions.custom_form_header_action/1},
          insert_footer_action: {:custom_footer, &FormOptions.custom_form_footer_action/1},
          action_icons: [default_save: "hero-bolt"] do
          stacked([
            :reference,
            :name,
            :quantity_initial,
            labels: [
              remove_label_action: :default_toggle_all,
              add_label_action: {:custom_label, &FormOptions.labels_label_action/1},
              add_header_action: {:custom_header, &FormOptions.labels_header_action/1},
              add_footer_action: {:custom_footer, &FormOptions.labels_footer_action/1}
            ]
          ])
        end

        show_layout :product, action_icons: [default_back: "←"] do
          inline([:reference, :name])
        end
      end
    end
  end

  @doc false
  @spec custom_form_header_action(map()) :: Rendered.t()
  def custom_form_header_action(assigns) do
    ~H"""
      <.button phx-disable-with="Saving..." name={"auix-save-#{@auix.module}"}>Custom Save {@auix.name}</.button>
    """
  end

  @doc false
  @spec custom_form_footer_action(map()) :: Rendered.t()
  def custom_form_footer_action(assigns) do
    ~H"""
      <.button phx-disable-with="Saving..." name={"auix-save-#{@auix.module}"}>Custom Footer Save {@auix.name}</.button>
    """
  end

  @doc false
  @spec labels_label_action(map()) :: Rendered.t()
  def labels_label_action(assigns) do
    ~H"""
      <.button type="button" name={"auix-custom-label-#{@field.key}"}>Custom label</.button>
    """
  end

  @doc false
  @spec labels_header_action(map()) :: Rendered.t()
  def labels_header_action(assigns) do
    ~H"""
      <.button type="button" name={"auix-custom-header-#{@field.key}"}>Custom header</.button>
    """
  end

  @doc false
  @spec labels_footer_action(map()) :: Rendered.t()
  def labels_footer_action(assigns) do
    ~H"""
      <.button type="button" name={"auix-custom-footer-#{@field.key}"}>Custom footer</.button>
    """
  end
end
