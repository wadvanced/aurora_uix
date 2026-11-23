defmodule Aurora.UixWeb.Test.Mirror.Handlers.HostRegistrar do
  @moduledoc false
  @behaviour Aurora.Uix.RendererRegistrar

  alias Aurora.UixWeb.Test.Mirror.Handlers.HostToggle

  @impl Aurora.Uix.RendererRegistrar
  def renderers, do: %{toggle_switch: &HostToggle.render/1}
end
