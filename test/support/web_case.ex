defmodule Aurora.UixWeb.Test.WebCase do
  @doc """
  Defines Aurora UIX test configuration.

  ## Returns
  Macro.t() - Aurora UIX test configuration quote.
  """
  @spec aurora_uix_for_test() :: Macro.t()
  def aurora_uix_for_test do
    quote do
      Module.register_attribute(__MODULE__, :auix_resource_metadata, persist: true)
      use Aurora.Uix
    end
  end

  @doc """
  Dispatches to the appropriate controller/live_view based on the given atom.

  ## Parameters
  - `which` (atom()) - The component type to dispatch to.

  ## Returns
  Macro.t() - Configuration quote for the specified component.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
