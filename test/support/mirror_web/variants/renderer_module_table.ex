defmodule Aurora.UixWeb.Test.Mirror.Variants.RendererModuleTable do
  @moduledoc """
  The `renderer-module-table` views variant: an `html_type` renderers table set on the views
  module.

  ## Key Features

  - Renders every checkbox field of the product with the toggle switch, through the
    `renderers:` option of `use Aurora.Uix`

  ## Key Constraints

  - Only for test scenarios
  - Used through `Aurora.UixWeb.Test.MirrorAsh.RendererModuleTable` and
    `Aurora.UixWeb.Test.MirrorCtx.RendererModuleTable`
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
    opts = Keyword.put(opts, :uix, quote(do: [renderers: %{checkbox: :toggle_switch}]))

    quote do
      use Aurora.UixWeb.Test.Mirror, unquote(opts)

      mirror_resource(:product)
      auix_create_ui()
    end
  end
end
