defmodule Aurora.UixWeb.Test.Mirror.Variants.DefaultInline do
  @moduledoc """
  The `default-inline` views variant: the default layouts with inline fields.

  ## Key Features

  - Declares its resources over the mirrored fixture of the chosen backend
  - Generates the views its scenarios mount

  ## Key Constraints

  - Only for test scenarios
  - Used through `Aurora.UixWeb.Test.MirrorAsh.DefaultInline` and `Aurora.UixWeb.Test.MirrorCtx.DefaultInline`
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
    quote do
      use Aurora.UixWeb.Test.Mirror, unquote(opts)

      mirror_resource(:product)
      auix_create_ui(default_fields_layout: :inline)
    end
  end
end
