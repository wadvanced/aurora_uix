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
  - `:get_streams` (function()): Reference to an arity one function.
        By default is `Aurora.Uix.Parsers.IndexParser.get_streams/1`.
  - `:index_new_link` (String.t()): URL for the "new" link. Default: "/<link_prefix><source>/new" or "#" if disabled.
  """

  @behaviour Aurora.Uix.Parser

  @doc """
  Returns the list of supported options for index and card views.

  ## Returns
  list(atom()) - List of supported option keys.

  """
  @spec get_options() :: list(atom())
  def get_options do
    [
      :index_new_link
    ]
  end

  @doc """
  Produces the default value for a given field in index/card configuration.

  ## Parameters
  - `parsed_opts` (map()) - Accumulator for parsed options.
  - `resource_config` (map()) - Resource configuration, must include `:schema` key.
  - `field` (atom()) - Field to produce the default value for.

  ## Returns
  function() - Default value for the specified field.

  """
  @spec default_value(map(), map(), atom()) :: term()
  def default_value(parsed_opts, _resource_config, :index_new_link),
    do: "/#{parsed_opts[:link_prefix]}#{parsed_opts[:source]}/new"
end
