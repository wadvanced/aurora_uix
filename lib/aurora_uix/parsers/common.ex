defmodule Aurora.Uix.Parsers.Common do
  @moduledoc """
  Handles common parsing logic for extracting metadata from Ecto schema modules.

  Provides mechanisms to:
  - Extract default values for various module attributes
  - Generate module-specific metadata
  - Transform schema information into user-friendly configurations

  Supports a wide range of configuration options for customizing UI generation.
  """

  use Aurora.Uix.Parsers.ParserCore

  @doc """
  Extracts schema metadata and merges common options.

  ## Parameters
  - `parsed_opts` (map()) - Map (accumulator) for parsed options.
  - `resource_config` (map()) - contains all the modules' configuration.
  - `opts` (`keyword()`) - Configuration options with keys:
    ### Common opts
    - `actions` - List of {position, function} tuples for UI actions
    - `add_actions` - Additional actions to append
    - `fields` -  Fields to be used, overrides the default list.
      The default list is created with all the fields found in the module, excluding
      the redacted fields.
    - `link_prefix` -  The link prefix inserted for paths. By default, this is blank. When used, the path is the link_prefix plus the source.
    - `name` -  Name of the schema. By default, uses the last part of the module name.
    - `remove` -  List of fields to be remove from the list.
      trying to remove non-existing fields will log a warning, but no error will be raised.
    - `remove_actions` -  Removes actions from the current list.
    - `source` : Key of the data. By default, resolves the source from the schema source value.
      Uses the function __schema__/1 passing :source as the argument.
    - `sub_title` -  Subtitle for the view, a :hide value will disallow its generation.
    - `template` -  Overrides the module that handles the generation.
      By default, uses Aurora.Uix.Web.AuroraTemplate, which is a sophisticated and highly opinionated template.
      There is also the Aurora.Uix.Web.PhoenixTemplate, which resembles the phoenix ui.
      The template can also be configured, application wide, by adding :aurora_uix, template: Module.
      New templates can be authored.
    - `title` -  Title for the UI. Uses the capitalized schema source as the title.
      #### Example
      Schema module: GeneralLedger.Account
      Schema source: "accounts"
      Title: "Accounts"

      #### Example
      Schema module: GeneralLedger.AccountReceivable
      Schema source: "account_receivables"
      Title: "Account receivables"

  ## Example
    iex> alias Aurora.Uix.Parsers.Common
    iex> defmodule Aurora.Uix.GeneralLedger.Account do
    ...>    use Ecto.Schema
    ...>    schema "accounts" do
    ...>      field :description, :string
    ...>      field :number, :string
    ...>      timestamps()
    ...>    end
    ...>  end
    iex> parsed = Common.parse(%{}, %{schema: Aurora.Uix.GeneralLedger.Account}, [])
    iex> parsed.name == "Account" # Name is taken from last part of the schema module name
    true
    iex> parsed.title == "Accounts" # Uses the capitalized schema source as the title.

    iex> alias Aurora.Uix.Parsers.Common
    iex> defmodule Aurora.Uix.GeneralLedger.AccountReceivable do
    ...>   use Ecto.Schema
    ...>   schema "account_receivables" do
    ...>     field :description, :string
    ...>     field :amount, :float
    ...>     timestamps()
    ...>   end
    ...> end
    iex> parsed = Common.parse(%{}, %{schema: Aurora.Uix.GeneralLedger.AccountReceivable}, [])
    iex> parsed.title == "Account Receivables"  # Uses the capitalized schema source as the title
  """
  @spec parse(map(), map(), keyword()) :: map()
  def parse(parsed_opts, resource_config, opts) do
    parsed_opts
    |> add_opt(resource_config, opts, :module)
    |> add_opt(resource_config, opts, :module_name)
    |> add_opt(resource_config, opts, :link_prefix)
    |> add_opt(resource_config, opts, :name)
    |> add_opt(resource_config, opts, :source)
    |> add_opt(resource_config, opts, :title)
  end

  @doc """
  Resolves default values for schema-derived properties.

  ### Parameters
    - `parsed_opts` (map()) - Map (accumulator) for parsed options.
    - `resource_config` (map()) -  contains all the modules' configuration.
    - `key` (`atom()`) -  Key value to produce the value from.

  """
  @spec default_value(map(), map(), atom()) :: any()

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
end
