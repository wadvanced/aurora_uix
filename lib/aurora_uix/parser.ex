defmodule Aurora.Uix.Parser do
  @moduledoc """
  Provides parsing utilities for transforming schema modules into configuration maps for UI rendering.

  This module serves as the primary interface for converting Ecto schema modules into structured
  configuration maps, enabling dynamic UI generation across the Aurora.Uix system.

  Key responsibilities:
  - Extract metadata from schema modules
  - Generate human-readable names and titles
  - Prepare configuration maps for different UI views (index, form, etc.)
  """

  alias Aurora.Uix.Parsers.Common
  alias Aurora.Uix.Parsers.ContextParser
  alias Aurora.Uix.Parsers.IndexParser

  @callback default_value(parsed_opts :: map, resource_config :: map, key :: atom) :: any

  @doc """
  Parses schema and options into a structured configuration map.

  ## Parameters
    - `resource_config` (map) - contains all the modules' configuration.
    - `opts` (keyword) - Configuration options. See full list in:
      - Common options: `Aurora.Uix.Parsers.Common.parse/3`
      - Index-specific options: `Aurora.Uix.Parsers.IndexParser.parse/3`
      - Context specific options: `Aurora.Uix.Parsers.ContextParser.parse/3`

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
  iex> Aurora.Uix.Parser.parse(%{schema: MySchema})
  %{
    module: "my_schema",
    module_name: "MySchema",
    name: "My Schema",
    title: "My Schemas",
    rows: [:streams, :my_schemas],
    source: "my_schemas",
    link_prefix: "",
    change_function: nil,
    create_function: nil,
    delete_function: nil,
    get_function: nil,
    list_function: nil,
    update_function: nil,
    new_function: nil,
    disable_index_new_link: false,
    disable_index_row_click: false,
    disable_index_show_entity_link: false,
    index_new_link: "/my_schemas/new",
    index_row_click: "my_schemas/[[entity]]",
    index_show_entity_link: "my_schemas/[[entity]]"
   }
  """
  @spec parse(map, keyword) :: map
  def parse(resource_config, opts \\ []) do
    opts =
      List.flatten(opts)

    %{}
    |> Common.parse(resource_config, opts)
    |> IndexParser.parse(resource_config, opts)
    |> ContextParser.parse(resource_config, opts)
  end
end
