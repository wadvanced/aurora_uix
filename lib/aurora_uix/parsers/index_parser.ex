defmodule Aurora.Uix.Parsers.IndexParser do
  @moduledoc """
  Parses index and card configuration options for Aurora.Uix UI components.

  ## Key features:
  - Handles parsing for rows, data sources, ordering, and filtering conditions.
  - Supports index and card-specific options, including layout overrides.
  - Extends base parsing with index-specific logic.

  ## Key constraints:
  - Expects resource configuration to include a schema module.
  - Relies on Phoenix streams and schema naming conventions for defaults.

  ## Index Options
  - `:rows` (list(atom())): List of fields to use. Defaults to Phoenix streams and schema name.
  - `:disable_index_row_click` (boolean()): Disables row click navigation in index views. Default: false.
  - `:disable_index_new_link` (boolean()): Disables the "new" link in index views. Default: false.
  - `:disable_index_show_entity_link` (boolean()): Disables the show entity link in index views. Default: false.
  - `:index_row_click` (String.t()): URL template for row click navigation. Default: "<link_prefix><source>/[[entity]]".
  - `:index_new_link` (String.t()): URL for the "new" link. Default: "/<link_prefix><source>/new" or "#" if disabled.
  - `:index_show_entity_link` (String.t()): URL template for show entity link. Default: "<link_prefix><source>/[[entity]]" or "#" if disabled.
  """

  @behaviour Aurora.Uix.Parser

  @doc """
  Returns the list of supported options for index and card views.

  ## Returns
  list(atom()) - List of supported option keys.

  """
  def get_options() do
    [
      :rows,
      :disable_index_row_click,
      :disable_index_new_link,
      :disable_index_show_entity_link,
      :index_row_click,
      :index_new_link,
      :index_show_entity_link
    ]
  end

  @doc """
  Produces the default value for a given field in index/card configuration.

  ## Parameters
  - `parsed_opts` (map()) - Accumulator for parsed options.
  - `resource_config` (map()) - Resource configuration, must include `:schema` key.
  - `field` (atom()) - Field to produce the default value for.

  ## Returns
  any() - Default value for the specified field.

  ## Examples
  ```elixir
  Aurora.Uix.Parsers.IndexParser.default_value(%{link_prefix: "/admin/", source: "accounts"}, %{schema: MyApp.Account}, :rows)
  #=> [:streams, :accounts]

  Aurora.Uix.Parsers.IndexParser.default_value(%{}, %{}, :disable_index_row_click)
  #=> false

  Aurora.Uix.Parsers.IndexParser.default_value(%{link_prefix: "/admin/", source: "accounts"}, %{}, :index_row_click)
  #=> "/admin/accounts/[[entity]]"
  ```
  """
  @spec default_value(map(), map(), atom()) :: any()
  def default_value(_parsed_opts, %{schema: module}, :rows) do
    :source
    |> module.__schema__()
    |> then(&[:streams, String.to_atom(&1)])
  end

  def default_value(_parsed_opts, _resource_config, :disable_index_row_click), do: false
  def default_value(_parsed_opts, _resource_config, :disable_index_new_link), do: false
  def default_value(_parsed_opts, _resource_config, :disable_index_show_entity_link), do: false

  def default_value(parsedOpts, _resource_config, :index_row_click) do
    "#{parsedOpts[:link_prefix]}#{parsedOpts[:source]}/[[entity]]"
  end

  def default_value(parsedOpts, _resource_config, :index_new_link) do
    if parsedOpts.disable_index_new_link,
      do: "#",
      else: "/#{parsedOpts[:link_prefix]}#{parsedOpts[:source]}/new"
  end

  def default_value(parsedOpts, _resource_config, :index_show_entity_link) do
    if parsedOpts.disable_index_show_entity_link,
      do: "#",
      else: "#{parsedOpts[:link_prefix]}#{parsedOpts[:source]}/[[entity]]"
  end
end
