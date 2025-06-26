defmodule Aurora.Uix.Parsers.Common do
  @moduledoc """
  Common parsing utilities for extracting and transforming metadata from Ecto schema modules.

  ## Key features
  - Extracts default values for module attributes (e.g., name, title, source).
  - Generates module-specific metadata for UI configuration.
  - Transforms schema information into user-friendly options.
  - Supports extensive configuration for customizing UI generation.

  ## Key constraints
  - Expects `:schema` key in resource config map.
  - Designed for use with Ecto schema modules.

  ## Common options
  - `:actions` (list({integer(), function()})) - List of {position, function} tuples for UI actions.
  - `:add_actions` (list()) - Additional actions to append.
  - `:fields` (list(atom())) - Fields to be used, overrides the default list. The default list is created with all the fields found in the module, excluding the redacted fields.
  - `:link_prefix` (binary()) - The link prefix inserted for paths. By default, this is blank. When used, the path is the link_prefix plus the source.
  - `:name` (binary()) - Name of the schema. By default, uses the last part of the module name.
  - `:remove` (list(atom())) - List of fields to be removed from the list. Trying to remove non-existing fields will log a warning, but no error will be raised.
  - `:remove_actions` (list()) - Removes actions from the current list.
  - `:source` (binary()) - Key of the data. By default, resolves the source from the schema source value. Uses the function `__schema__/1` passing `:source` as the argument.
  - `:sub_title` (binary() | :hide) - Subtitle for the view, a `:hide` value will disallow its generation.
  - `:template` (module()) - Overrides the module that handles the generation. By default, uses `Aurora.Uix.Web.AuroraTemplate`, which is a sophisticated and highly opinionated template. There is also the `Aurora.Uix.Web.PhoenixTemplate`, which resembles the Phoenix UI. The template can also be configured application-wide by adding `:aurora_uix, template: Module`. New templates can be authored.
  - `:title` (binary()) - Title for the UI. Uses the capitalized schema source as the title.
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
      :title
    ]
  end

  @doc """
  Resolves the default value for a given schema-derived property.

  ## Parameters
  - `parsed_opts` (map()) - Accumulator for parsed options.
  - `resource_config` (map()) - Contains the module's configuration. Must include `:schema` key.
  - `key` (atom()) - The property key to resolve.

  ## Returns
  term() - The resolved default value for the property.

  ## Examples
  |||elixir
  Aurora.Uix.Parsers.Common.default_value(%{}, %{schema: MyApp.Blog.Post}, :module)
  #=> "post"

  Aurora.Uix.Parsers.Common.default_value(%{}, %{schema: MyApp.Blog.Post}, :module_name)
  #=> "Post"

  Aurora.Uix.Parsers.Common.default_value(%{}, %{schema: MyApp.Blog.Post}, :title)
  #=> "Posts"
  |||
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

  def default_value(_parsed_opts, _resource_config, :link_prefix), do: ""

  def default_value(_parsed_opts, %{schema: module}, :title) do
    :source
    |> module.__schema__()
    |> capitalize()
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
