defmodule Aurora.UixWeb.Test.RoutesHelper do
  alias Aurora.UixWeb.Test.RoutesHelper

  defmacro register_crud(module, link_prefix) do
    routes =
      quote do
        link = "/#{unquote(link_prefix)}"
        # auix_live_resources(link, unquote(module))
        index_module = Module.concat(unquote(module), Index)
        show_module = Module.concat(unquote(module), Show)
        live("/#{link}", index_module, :index)
        live("/#{link}/new", index_module, :new)
        live("/#{link}/:id/edit", index_module, :edit)
        live("/#{link}/:id", show_module, :show)
        live("/#{link}/:id/show/edit", show_module, :edit)
      end

    quote do
      unquote(routes)
    end
  end

  @doc """
  Registers CRUD routes for product-related modules.

  ## Parameters
  - `module` (module()) - The base module.
  - `prefix` (binary()) - The URL prefix for the routes.

  ## Returns
  Macro.t() - CRUD routes configuration quote for product modules.
  """
  @spec register_product_crud(module(), binary()) :: Macro.t()
  defmacro register_product_crud(module, prefix) do
    quote do
      unquote(module)
      |> Module.concat(Product)
      |> RoutesHelper.register_crud("#{unquote(prefix)}products")

      unquote(module)
      |> Module.concat(ProductTransaction)
      |> RoutesHelper.register_crud("#{unquote(prefix)}product_transactions")

      unquote(module)
      |> Module.concat(ProductLocation)
      |> RoutesHelper.register_crud("#{unquote(prefix)}product_locations")
    end
  end
end
