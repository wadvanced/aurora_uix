defmodule AuroraUix.Parser do
  @moduledoc """
  Provides parsing utilities for transforming schema modules into configuration maps for UI rendering.

  This module serves as the primary interface for converting Ecto schema modules into structured
  configuration maps, enabling dynamic UI generation across the AuroraUix system.

  Key responsibilities:
  - Extract metadata from schema modules
  - Generate human-readable names and titles
  - Prepare configuration maps for different UI views (index, form, etc.)
  """

  alias AuroraUix.Parsers.Common
  alias AuroraUix.Parsers.IndexParser

  @callback default_value(module :: module, key :: atom) :: any

  @doc """
  Parses schema and options into a structured configuration map.

  ## Parameters
    - `module` (module) - Ecto schema module containing field definitions
    - `opts` (Keyword.t()) - Configuration options. See full list in:
      - Common options: `AuroraUix.Parsers.Common.parse/3`
      - Index-specific options: `AuroraUix.Parsers.IndexParser.parse/3`

  ## Returns
  A map containing:
    - Schema metadata (module name, source table, display names)
    - Field configuration
    - View-specific settings (rows configuration for index views)
    - Template rendering options

  ## Example
  iex> defmodule MySchema do
  ...>   use Ecto.Schema
  ...>   schema "my_schemas" do
  ...>     field :reference, :string
  ...>   end
  ...> end
  iex> AuroraUix.Parser.parse(MySchema)
  %{
    module: "my_schema",
    module_name: "MySchema",
    name: "My Schema",
    title: "My Schemas",
    rows: [:streams, :my_schemas],
    source: "my_schemas",
    link: "my_schemas"
  }
  """
  @spec parse(module, Keyword.t()) :: map
  def parse(module, opts \\ []) do
    opts = List.flatten(opts)

    %{}
    |> Common.parse(module, opts)
    |> IndexParser.parse(module, opts)
  end
end
