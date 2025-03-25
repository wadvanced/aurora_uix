defmodule AuroraUix.Parsers.IndexParser do
  @moduledoc """
  Specializes in parsing index and card-related configuration options for AuroraUix UI components.

  Handles specific parsing requirements for:
  - Defining rows and data sources
  - Configuring default ordering
  - Applying filtering conditions

  Extends the base parsing behavior with index-specific logic.
  """

  use AuroraUix.Parsers.ParserCore

  @doc """
  Parse module and :index options.

  ## Parameters
    - `parsed_opts` (`map`) - Map (accumulator) for parsed options.
    - `resource_config` (map): Contains all the modules' configuration.
    - `opts` (Keyword.t()): List of options, the available ones depends on the type of view.

  ## Options
    - :index and :card opts
      - `rows ([])`: List of fields to use. By default, relies on Phoenix streams and the name of
      the schema.
      ### Example
        Schema module: Account, rows [:streams, :accounts]

      - `order_by: [{field, :asc | :desc}]`: Overrides the default order of the list / card.
          By default, the order is by id for numeric id, and by created_at (desc) for compose id or string id.
      - `where: string`: Adds a where like string.

    - :card :form opts
      - `layout: Uix.Formatter`: Overrides the default layout by using a formatter. See details in the module.

  """
  @spec parse(map, map, Keyword.t()) :: map
  def parse(parsed_opts, resource_config, opts) do
    add_opt(parsed_opts, resource_config, opts, :rows)
  end

  @doc """
  Produce the default value for the given field.

  ## Parameters
    - `parsed_opts` (`map`) - Map (accumulator) for parsed options.
    - `resource_config` (map): contains all the modules' configuration.
    - `field` (atom): Field to produce the default value for.
  """
  @spec default_value(map, map, atom) :: any
  def default_value(_parsed_opts, %{schema: module}, :rows) do
    :source
    |> module.__schema__()
    |> then(&[:streams, String.to_atom(&1)])
  end
end
