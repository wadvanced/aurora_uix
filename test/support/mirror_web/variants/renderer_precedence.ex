defmodule Aurora.UixWeb.Test.Mirror.Variants.RendererPrecedence do
  @moduledoc """
  The `renderer-precedence` views variant: `html_type` renderers tables at every level.

  ## Key Features

  - Sets a table on the views module, on the resource, on `auix_create_ui` and on
    `index_columns`, and a field slot on `deleted`

  ## Key Constraints

  - Only for test scenarios
  - Used through `Aurora.UixWeb.Test.MirrorAsh.RendererPrecedence` and
    `Aurora.UixWeb.Test.MirrorCtx.RendererPrecedence`
  """

  @doc """
  Declares the variant's resources and UI in the caller.

  ## Parameters
  - `opts` (keyword()) - `backend: :ash | :ctx`.

  ## Returns
  Macro.t() - The quoted variant.
  """
  @spec __using__(keyword()) :: Macro.t()
  defmacro __using__(opts) do
    opts = Keyword.put(opts, :uix, quote(do: [renderers: %{number: :progress_bar}]))

    quote do
      use Aurora.UixWeb.Test.Mirror, unquote(opts)

      mirror_resource :product do
        renderers(%{text: :badge, number: :rating})
        field(:deleted, show_renderer: :default_checkbox)
      end

      auix_create_ui renderers: %{
                       checkbox: :toggle_switch,
                       text: :default_text,
                       number: :not_a_renderer
                     } do
        index_columns(:product, [:reference, :inactive, :quantity_at_hand],
          renderers: %{checkbox: :default_checkbox}
        )
      end
    end
  end
end
