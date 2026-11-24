defmodule Aurora.UixWeb.Test.Mirror.Variants.PairedFormHost do
  @moduledoc """
  The `paired-form-host` views variant: a LiveView that renders a form component of another views
  module.

  ## Key Features

  - Pairs the host with the product location reference form of `ComponentsPaired`
  - Renders the form component for the `entity_id` of the session and shows the component that
    reported a save

  ## Key Constraints

  - Only for test scenarios
  - Mounted with `live_isolated/3`; it has no route
  - Used through `Aurora.UixWeb.Test.MirrorAsh.PairedFormHost` and
    `Aurora.UixWeb.Test.MirrorCtx.PairedFormHost`
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
        edit_layout(:product_location, use: unquote(views).auix_module(:reference_form))
      end

      @impl true
      def mount(_params, session, socket) do
        {:ok,
         socket
         |> assign(:entity_id, Map.fetch!(session, "entity_id"))
         |> assign(:form_module, unquote(views).auix_module(:reference_form))
         |> assign(:saved, nil)}
      end

      @impl true
      def render(var!(assigns)) do
        ~H"""
        <div id="auix-paired-host">
          <.live_component
            module={@form_module}
            id="location-form"
            resource={:product_location}
            entity_id={@entity_id}
          />
          <p id="auix-paired-saved" data-component={@saved}></p>
        </div>
        """
      end

      @impl true
      def handle_info({Aurora.Uix, component_id, {:saved, _entity}}, socket),
        do: {:noreply, assign(socket, :saved, component_id)}
    end
  end
end
