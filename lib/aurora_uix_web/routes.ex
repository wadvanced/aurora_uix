defmodule Aurora.UixWeb.Routes do
  @moduledoc """
  This module defines macros for loading routes in the Aurora.UixWeb application.
  """

  @doc """
  Macro to load routes for the application.
  """
  defmacro load_routes() do
    quote do
      auix_live_resources("/guide-overview-products", Overview.Product)
    end
  end
end
