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
        live("/#{link}/:id/show", index_module, :show)
        live("/#{link}/:id/show-edit", index_module, :show_edit)
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
  Registers the CRUD routes of a mirror views variant, on both backends.

  ## Parameters
  - `variant` (module()) - The variant alias, such as `Default`.
  - `slug` (binary()) - The literal slug of the variant.
  - `sources` (list(binary())) - The literal list of resource sources to register.

  ## Returns
  Macro.t() - One `register_crud/2` call per backend and source, routed at
  `/mirror-<backend>-<slug>-<source>`.
  """
  @spec register_mirror(module(), binary(), [binary()]) :: Macro.t()
  defmacro register_mirror(variant, slug, sources) do
    routes =
      for {backend, backend_slug} <- [{MirrorAsh, "ash"}, {MirrorCtx, "ctx"}],
          source <- sources do
        schema = mirror_schema(source)
        link_prefix = "mirror-#{backend_slug}-#{slug}-#{source}"

        quote do
          [unquote(backend), unquote(variant), unquote(schema)]
          |> Module.concat()
          |> RoutesHelper.register_crud(unquote(link_prefix))
        end
      end

    {:__block__, [], routes}
  end

  ## PRIVATE ##

  @spec mirror_schema(binary()) :: module()
  defp mirror_schema("products"), do: Product
  defp mirror_schema("product_locations"), do: ProductLocation
  defp mirror_schema("product_transactions"), do: ProductTransaction
  defp mirror_schema("product_barcodes"), do: ProductBarcode
  defp mirror_schema("suppliers"), do: Supplier
end
