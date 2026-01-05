defmodule Aurora.UixWeb.Test.RoutesHelper do
  @moduledoc """
  Provides helper macros for defining routes in tests.
  """
  alias Aurora.UixWeb.Test.RoutesHelper

  @doc """
  Registers CRUD routes for a given module and link prefix.

  ## Parameters
  - `module` (module()) - The base module for the routes.
  - `link_prefix` (binary()) - The URL prefix for the routes.

  ## Returns
  Macro.t() - A quote with the generated CRUD routes.
  """
  @spec register_crud(module(), binary()) :: Macro.t()
  defmacro register_crud(module, link_prefix) do
    routes =
      quote do
        link = "/#{unquote(link_prefix)}"
        index_module = Module.concat(unquote(module), Index)
        live("/#{link}", index_module, :index)
        live("/#{link}/new", index_module, :new)
        live("/#{link}/:id/edit", index_module, :edit)
        live("/#{link}/:id", index_module, :show)
        live("/#{link}/:id/show/edit", index_module, :edit)
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

  @doc """
  Registers CRUD routes for user-related modules.

  ## Parameters
  - `module` (module()) - The base module.
  - `prefix` (binary()) - The URL prefix for the routes.

  ## Returns
  Macro.t() - CRUD routes configuration quote for user modules.
  """
  @spec register_user_crud(module(), binary()) :: Macro.t()
  defmacro register_user_crud(module, prefix) do
    quote do
      unquote(module)
      |> Module.concat(User)
      |> RoutesHelper.register_crud("#{unquote(prefix)}users")
    end
  end
end
