defmodule AuroraUix.Parsers.IndexParser do
  @moduledoc """
  Parse common options and adds the module related values.
  """

  use AuroraUix.Parsers.BaseParser

  @doc """
  Parse module and :index options.

  ## PARAMETERS
  * `module` (module): Schema module to be used for gathering field information.
  * `opts` (Keyword.t()): List of options, the available ones depends on the type of view.
    ### :index and :card opts
    * `rows ([])`: List of fields to use. By default, relies on Phoenix streams and the name of
    the schema.
    #### Example
    Schema module: Account,
    rows [:streams, :accounts]
    * `order_by: [{field, :asc | :desc}]`: Overrides the default order of the list / card.
      By default, the order is by id for numeric id, and by created_at (desc) for compose id or string id.
    * `where: string`: Adds a where like string.

    ### :card :form opts
    * `layout: Uix.Formatter`: Overrides the default layout by using a formatter. See details in the module.

  """
  @spec parse(map, module, Keyword.t()) :: map
  def parse(parsed_opts, module, opts) do
    add_opt(parsed_opts, module, opts, :rows)
  end

  @doc """
  Produce the default value for the given field.

  ## Parameters
    - `module (module)`: Schema module.
    - `field (atom)`: Field to produce the default value for.
  """
  @spec default_value(module, atom) :: any
  def default_value(module, :rows) do
    :source
    |> module.__schema__()
    |> then(&[:streams, String.to_atom(&1)])
  end
end
