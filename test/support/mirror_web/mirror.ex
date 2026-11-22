defmodule Aurora.UixWeb.Test.Mirror do
  @moduledoc """
  Declares the resources of a mirror views module for one backend.

  ## Key Features

  - `use Aurora.UixWeb.Test.Mirror, backend: :ash | :ctx` prepares a views module for that backend
  - `mirror_resource/3` declares a resource over the mirrored fixture of the chosen backend, so
    one variant definition yields an Ash and an Ecto views module

  ## Key Constraints

  - Only for test scenarios
  - The backend is stored on the caller before any `mirror_resource/3` call expands
  - Only the schemas of the mirrored fixture are known
  """

  @doc """
  Prepares the caller as a mirror views module for `backend`.

  ## Parameters
  - `opts` (keyword()) - `backend: :ash | :ctx`.

  ## Returns
  Macro.t() - The quoted setup of the views module.
  """
  @spec __using__(keyword()) :: Macro.t()
  defmacro __using__(backend: backend) do
    Module.put_attribute(__CALLER__.module, :mirror_backend, backend)

    quote do
      Module.register_attribute(__MODULE__, :auix_resource_metadata, persist: true)
      use Aurora.Uix

      import Aurora.UixWeb.Test.Mirror,
        only: [mirror_resource: 1, mirror_resource: 2, mirror_resource: 3]
    end
  end

  @doc """
  Declares the resource `name` over the mirrored fixture of the caller's backend.

  ## Parameters
  - `name` (atom()) - The resource name.
  - `opts` (keyword()) - `schema:` names the mirrored schema (defaults to `name`); a `:do` key is
    taken as the block when no block is given.
  - `block` (keyword()) - The `auix_resource_metadata` body.

  ## Returns
  Macro.t() - The quoted `auix_resource_metadata` call.
  """
  @spec mirror_resource(atom(), keyword(), keyword()) :: Macro.t()
  defmacro mirror_resource(name, opts \\ [], block \\ [do: nil]) do
    {opts, block} =
      if Keyword.has_key?(opts, :do) and block == [do: nil],
        do: {[], opts},
        else: {opts, block}

    schema = Keyword.get(opts, :schema, name)
    backend = Module.get_attribute(__CALLER__.module, :mirror_backend)
    source_lines = source_lines(backend, schema)

    quote do
      auix_resource_metadata unquote(name) do
        unquote(source_lines)
        unquote(block[:do])
      end
    end
  end

  ## PRIVATE ##

  @spec source_lines(:ash | :ctx, atom()) :: Macro.t()
  defp source_lines(:ash, schema) do
    {_ctx_module, ash_module} = modules(schema)
    quote(do: ash_resource(unquote(ash_module)))
  end

  defp source_lines(:ctx, schema) do
    {ctx_module, _ash_module} = modules(schema)

    quote do
      context(Aurora.Uix.Test.MirrorCtx)
      schema(unquote(ctx_module))
    end
  end

  @spec modules(atom()) :: {module(), module()}
  defp modules(:product),
    do: {Aurora.Uix.Test.MirrorCtx.Product, Aurora.Uix.Test.MirrorAsh.Product}

  defp modules(:product_location),
    do: {Aurora.Uix.Test.MirrorCtx.ProductLocation, Aurora.Uix.Test.MirrorAsh.ProductLocation}

  defp modules(:product_transaction),
    do:
      {Aurora.Uix.Test.MirrorCtx.ProductTransaction, Aurora.Uix.Test.MirrorAsh.ProductTransaction}

  defp modules(:product_barcode),
    do: {Aurora.Uix.Test.MirrorCtx.ProductBarcode, Aurora.Uix.Test.MirrorAsh.ProductBarcode}

  defp modules(:supplier),
    do: {Aurora.Uix.Test.MirrorCtx.Supplier, Aurora.Uix.Test.MirrorAsh.Supplier}
end
