defmodule Aurora.UixWeb.Test.Mirror.Variants.PairedIndexHost do
  @moduledoc """
  The `paired-index-host` views variant: a LiveView that renders an index component of another
  views module.

  ## Key Features

  - Pairs the host with the compact index of `ComponentsPaired` for the product locations
  - Renders the index component for the product locations

  ## Key Constraints

  - Only for test scenarios
  - Mounted with `live_isolated/3`; it has no route
  - Used through `Aurora.UixWeb.Test.MirrorAsh.PairedIndexHost` and
    `Aurora.UixWeb.Test.MirrorCtx.PairedIndexHost`
  """

  alias Aurora.UixWeb.Test.Mirror

  @doc """
  Declares the host LiveView in the caller.

  ## Parameters
  - `opts` (keyword()) - `backend: :ash | :ctx`.

  ## Returns
  Macro.t() - The quoted host.
  """
  @spec __using__(keyword()) :: Macro.t()
  defmacro __using__(opts) do
    views = Mirror.sibling(opts[:backend], ComponentsPaired)

    quote do
      use Aurora.UixWeb.Test, :live_view
      use Aurora.UixWeb.Test.Mirror, unquote(opts)

      @auix_resource_metadata %{
        product_location: unquote(views).auix_resource(:product_location)
      }

      auix_create_ui generate: [] do
        index_columns(:product_location, use: unquote(views).auix_module(:index_compact))
      end

      @impl true
      def mount(_params, _session, socket),
        do: {:ok, assign(socket, :index_module, unquote(views).auix_module(:index_compact))}

      @impl true
      def render(var!(assigns)) do
        ~H"""
        <div id="auix-paired-host">
          <.live_component module={@index_module} id="locations" resource={:product_location} />
        </div>
        """
      end
    end
  end
end
