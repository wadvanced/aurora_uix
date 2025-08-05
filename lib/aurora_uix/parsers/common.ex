defmodule Aurora.Uix.Parsers.Common do
  @moduledoc """
  Provides default value resolution for schema-derived properties in Aurora.Uix parsers.

  This module implements the `Aurora.Uix.Parser` behaviour and serves as a common utility
  for resolving default values from Ecto schema modules. It supports extracting metadata
  such as module names, titles, sources, and primary keys directly from schema definitions.

  ## Key features
  - Resolves default values for eight core schema properties: `:module`, `:module_name`,
    `:link_prefix`, `:name`, `:source`, `:title`, and `:primary_key`.
  - Automatically extracts schema source and primary key information using `__schema__/1`.
  - Transforms module names into user-friendly formats with proper capitalization.
  - Provides consistent naming conventions across the Aurora.Uix system.

  ## Key constraints
  - Requires `:schema` key in resource config map containing an Ecto schema module.
  - Schema module must implement `__schema__/1` function (standard Ecto requirement).
  - Only handles the specific property keys returned by `get_options/0`.

  ## Properties
  When a property is not present in the metadata, this module provides default values:
  - `:module` - Defaults to underscored module name (e.g., "blog_post" from MyApp.BlogPost)
  - `:module_name` - Defaults to last part of module name (e.g., "BlogPost" from MyApp.BlogPost)
  - `:link_prefix` - Defaults to empty string
  - `:name` - Defaults to capitalized module name (e.g., "Blog Post" from MyApp.BlogPost)
  - `:source` - Defaults to schema table name from `__schema__(:source)`
  - `:title` - Defaults to capitalized schema source name
  - `:primary_key` - Defaults to primary key fields from `__schema__(:primary_key)`
  """

  @behaviour Aurora.Uix.Parser

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
      :link_prefix,
      :name,
      :source,
      :source_key,
      :title,
      :primary_key
    ]
  end

  @doc """
  Resolves the default value for a given schema-derived property.

  ## Parameters
  - `parsed_opts` (map()) - Accumulator for parsed options.
  - `resource_config` (map()) - Contains the module's configuration:
    * `:schema` (module()) - The Ecto schema module to extract metadata from.
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
    |> capitalize()
  end

  def default_value(_parsed_opts, %{schema: module}, :source), do: module.__schema__(:source)

  def default_value(_parsed_opts, %{schema: module}, :source_key),
    do: :source |> module.__schema__() |> String.to_atom()

  def default_value(_parsed_opts, _resource_config, :link_prefix), do: ""

  def default_value(_parsed_opts, %{schema: module}, :title) do
    :source
    |> module.__schema__()
    |> capitalize()
  end

  def default_value(_parsed_opts, %{schema: module}, :primary_key) do
    case module.__schema__(:primary_key) do
      [] -> :fields |> module.__schema__() |> List.first() |> then(&[&1])
      key -> key
    end
  end

  ## PRIVATE

  # Converts a string to capitalized words, splitting on underscores.
  @spec capitalize(binary()) :: binary()
  defp capitalize(string) do
    string
    |> Macro.underscore()
    |> String.split("_")
    |> Enum.map_join(" ", &String.capitalize/1)
  end
end
