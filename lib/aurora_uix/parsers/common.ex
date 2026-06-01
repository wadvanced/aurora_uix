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

  @impl true
  def get_options(_resource_config, _opts) do
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

  @impl true
  def option_value(_parsed_opts, %{schema: module}, _opts, :module) do
    module
    |> Module.split()
    |> List.last()
    |> Macro.underscore()
  end

  def option_value(_parsed_opts, %{schema: module}, _opts, :module_name) do
    module
    |> Module.split()
    |> List.last()
  end

  def option_value(parsed_opts, resource_config, opts, :name) do
    has_key? = Keyword.has_key?(opts, :name)
    process_name(parsed_opts, resource_config, opts, has_key?)
  end

  def option_value(_parsed_opts, %{schema: module}, _opts, :source),
    do: module.__schema__(:source)

  def option_value(_parsed_opts, %{schema: module}, _opts, :source_key),
    do: :source |> module.__schema__() |> CommonHelper.safe_atom()

  def option_value(parsed_opts, resource_config, opts, :title) do
    has_key? = Keyword.has_key?(opts, :title)
    process_title(parsed_opts, resource_config, opts, has_key?)
  end

  def option_value(_parsed_opts, %{schema: module}, _opts, :primary_key) do
    module.__schema__(:primary_key)
  end

  @impl true
  def fill_missing_options(parsed_opts, _resource_config), do: parsed_opts

  ## PRIVATE
  @spec process_name(map(), map(), keyword(), boolean()) :: binary()
  defp process_name(_parsed_opts, _resource_config, opts, true) do
    case opts[:name] do
      nil -> ""
      value -> value
    end
  end

  defp process_name(_parsed_opts, %{schema: module}, _opts, false) do
    module
    |> Module.split()
    |> List.last()
    |> CommonHelper.capitalize()
  end

  @spec process_title(map(), map(), keyword(), boolean()) :: binary()
  defp process_title(_parsed_opts, _resource_config, opts, true) do
    case opts[:title] do
      # Nil will be blank so title: nil is valid
      nil -> ""
      value -> value
    end
  end

  defp process_title(_parsed_opts, %{schema: module}, _opts, false) do
    :source
    |> module.__schema__()
    |> CommonHelper.capitalize()
  end
end
