defmodule Aurora.UixWeb.Test.Mirror.Variants.NamedHost do
  @moduledoc """
  The `named-host` views variant: a pairing declared without generating modules.

  ## Key Features

  - Declares its resources over the mirrored fixture of the chosen backend
  - Generates the views its scenarios mount

  ## Key Constraints

  - Only for test scenarios
  - Used through `Aurora.UixWeb.Test.MirrorAsh.NamedHost` and `Aurora.UixWeb.Test.MirrorCtx.NamedHost`
  """

  alias Aurora.UixWeb.Test.Mirror

  @doc """
  Declares the variant's resources and UI in the caller.

  ## Parameters
  - `opts` (keyword()) - `backend: :ash | :ctx`.

  ## Returns
  Macro.t() - The quoted variant.
  """
  @spec __using__(keyword()) :: Macro.t()
  defmacro __using__(opts) do
    forms = Mirror.sibling(opts[:backend], NamedForms)

    quote do
      use Aurora.UixWeb.Test.Mirror, unquote(opts)

      @auix_resource_metadata %{
        product_location: unquote(forms).auix_resource(:product_location)
      }

      auix_create_ui generate: [] do
        edit_layout(:product_location, use: unquote(forms).auix_module(:reference_form))
      end
    end
  end
end
