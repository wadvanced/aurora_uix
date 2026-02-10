defmodule Aurora.UixWeb.Routes do
  @moduledoc """
  This module defines macros for loading routes in the Aurora.UixWeb application.
  """

  @doc """
  Macro to load routes for the application.
  """
  defmacro load_routes do
    quote do
      auix_live_resources("/products", Overview.Product)
      auix_live_resources("/product-locations", Overview.ProductLocation)
      auix_live_resources("/product_transactions", Overview.ProductTransaction)

      # Using ash framework
      auix_live_resources("/posts", AshOverview.Post)
      auix_live_resources("/authors", AshOverview.Author)
      auix_live_resources("/categories", AshOverview.Category)
      auix_live_resources("/tags", AshOverview.Tag)
    end
  end
end
