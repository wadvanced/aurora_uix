defmodule Aurora.UixWeb.Test.Mirror.Variants.ManyToMany do
  @moduledoc """
  The `many-to-many` views variant: the suppliers of a product as a checkbox group in the form and
  a read-only list in the show view.

  ## Key Features

  - Declares the suppliers membership of a product labelled by the supplier name
  - Lists the membership in the product form and show layouts

  ## Key Constraints

  - Only for test scenarios
  - Used through `Aurora.UixWeb.Test.MirrorAsh.ManyToMany` and
    `Aurora.UixWeb.Test.MirrorCtx.ManyToMany`
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

      mirror_resource :product do
        field(:suppliers, option_label: :name)
      end

      mirror_resource(:supplier)

      auix_create_ui do
        edit_layout :product do
          stacked([:reference, :name, :quantity_initial, :suppliers])
        end

        show_layout :product do
          stacked([:reference, :name, :suppliers])
        end
      end
    end
  end
end
