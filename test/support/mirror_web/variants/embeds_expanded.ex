defmodule Aurora.UixWeb.Test.Mirror.Variants.EmbedsExpanded do
  @moduledoc """
  The `embeds-expanded` views variant: the embedded contacts of a product opened by default, with
  replaced action icons.

  ## Key Features

  - Declares the contacts as expanded in the layouts only: a boolean in the form layout and a
    function of the assigns in the show layout
  - Replaces the add and remove entry icons of the contacts

  ## Key Constraints

  - Only for test scenarios
  - Used through `Aurora.UixWeb.Test.MirrorAsh.EmbedsExpanded` and
    `Aurora.UixWeb.Test.MirrorCtx.EmbedsExpanded`
  """

  alias Aurora.UixWeb.Test.Mirror.Variants.EmbedsExpanded

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
        edit_layout :product do
          stacked([
            :reference,
            :name,
            :quantity_initial,
            contacts: [
              expanded: true,
              action_icons: [
                default_header_enable_add_entry: "hero-sparkles",
                default_remove_entry: "hero-x-mark"
              ]
            ]
          ])
        end

        show_layout :product do
          stacked([:reference, :name, contacts: [expanded: &EmbedsExpanded.always_expanded/1]])
        end
      end
    end
  end

  @doc false
  @spec always_expanded(map()) :: boolean()
  def always_expanded(_assigns), do: true
end
