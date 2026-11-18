defmodule Aurora.Uix.Layout.CreateUI.IndexColumns do
  @moduledoc """
  The `index_columns` macro of the layout DSL, over the `auix_index_columns` entity.

  ## Key Features
  - `index_columns resource, fields, options do card ... end`, every part after the resource
    optional.

  ## Key Constraints
  - The macro always passes a block, because Spark reads the keyword list of a block-less call
    to an entity with nested entities as entity options.
  - A call with a card and no field list writes its options after `[]`.
  """

  @doc """
  Declares the index columns of a resource, with an optional card block.

  ## Parameters
  - `resource` (Macro.t()) - The resource.
  - `columns` (Macro.t()) - The field list, or the `do` block holding the card.

  ## Returns
  `Macro.t()` - The `auix_index_columns` entity call.
  """
  @spec index_columns(Macro.t(), Macro.t()) :: Macro.t()
  defmacro index_columns(resource, do: block), do: entity(resource, [], [], block)
  defmacro index_columns(resource, columns), do: entity(resource, columns, [], nil)

  @doc """
  Declares the index columns of a resource with options, or with a card block.

  ## Parameters
  - `resource` (Macro.t()) - The resource.
  - `columns` (Macro.t()) - The field list.
  - `opts` (Macro.t()) - The layout options, or the `do` block holding the card.

  ## Returns
  `Macro.t()` - The `auix_index_columns` entity call.
  """
  @spec index_columns(Macro.t(), Macro.t(), Macro.t()) :: Macro.t()
  defmacro index_columns(resource, columns, do: block), do: entity(resource, columns, [], block)
  defmacro index_columns(resource, columns, opts), do: entity(resource, columns, opts, nil)

  @doc """
  Declares the index columns of a resource with options and a card block.

  ## Parameters
  - `resource` (Macro.t()) - The resource.
  - `columns` (Macro.t()) - The field list.
  - `opts` (Macro.t()) - The layout options.
  - `block` (Macro.t()) - The `do` block holding the card.

  ## Returns
  `Macro.t()` - The `auix_index_columns` entity call.
  """
  @spec index_columns(Macro.t(), Macro.t(), Macro.t(), Macro.t()) :: Macro.t()
  defmacro index_columns(resource, columns, opts, do: block),
    do: entity(resource, columns, opts, block)

  ## PRIVATE

  @spec entity(Macro.t(), Macro.t(), Macro.t(), Macro.t()) :: Macro.t()
  defp entity(resource, columns, opts, block) do
    quote do
      auix_index_columns(unquote(resource), unquote(columns), unquote(opts), do: unquote(block))
    end
  end
end
