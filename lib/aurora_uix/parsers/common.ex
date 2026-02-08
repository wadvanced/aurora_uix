defmodule Aurora.Uix.Parsers.Common do
  @moduledoc """
  Provides default value resolution for schema-derived properties in Aurora.Uix parsers.

  Implements the `Aurora.Uix.Parser` behaviour to resolve default values from Ecto schema
  modules. Supports extracting metadata such as module names, titles, sources, and primary
  keys directly from schema definitions.

  ## Supported Properties

  - `:module` - Underscored module name (e.g., "blog_post" from MyApp.BlogPost)
  - `:module_name` - Last part of module name (e.g., "BlogPost" from MyApp.BlogPost)
  - `:name` - Capitalized module name (e.g., "Blog Post" from MyApp.BlogPost)
  - `:source` - Schema table name from `__schema__(:source)`
  - `:source_key` - Safe atom conversion of source
  - `:title` - Capitalized schema source name
  - `:primary_key` - Primary key fields from `__schema__(:primary_key)`
  """

  @behaviour Aurora.Uix.Parser

  alias Aurora.Uix.Helpers.Common, as: CommonHelper

  @doc """
  Returns the list of supported option keys for schema metadata extraction.

  ## Returns
  list(atom()) - List of supported option keys.
  """
  @spec get_options() :: list(atom())
  def get_options do
    [
      :module,
      :module_name,
      :name,
      :source,
      :source_key,
      :title,
      :primary_key
    ]
  end

  @doc """
  Resolves the default value for a given schema-derived property.

  Uses the Ecto schema module to extract metadata. Requires `:schema` key in
  resource_config containing a valid Ecto schema module.

  ## Parameters
  - `parsed_opts` (map()) - Accumulator for parsed options.
  - `resource_config` (map()) - Contains `:schema` (module()) - the Ecto schema module.
  - `key` (atom()) - The property key to resolve.

  ## Returns
  term() - The resolved default value for the property.
  """
  @spec default_value(map(), map(), atom()) :: term()
  def default_value(_parsed_opts, %{schema: module}, :module) do
    module
    |> Module.split()
    |> List.last()
    |> Macro.underscore()
  end

  def default_value(_parsed_opts, %{schema: module}, :module_name) do
    module
    |> Module.split()
    |> List.last()
  end

  def default_value(_parsed_opts, %{schema: module}, :name) do
    module
    |> Module.split()
    |> List.last()
    |> CommonHelper.capitalize()
  end

  def default_value(_parsed_opts, %{schema: module}, :source), do: module.__schema__(:source)

  def default_value(_parsed_opts, %{schema: module}, :source_key),
    do: :source |> module.__schema__() |> CommonHelper.safe_atom()

  def default_value(_parsed_opts, %{schema: module}, :title) do
    :source
    |> module.__schema__()
    |> CommonHelper.capitalize()
  end

  def default_value(_parsed_opts, %{schema: module}, :primary_key) do
    module.__schema__(:primary_key)
  end
end
