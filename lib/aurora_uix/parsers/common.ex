defmodule AuroraUix.Parsers.Common do
  @moduledoc """
  Handles common parsing logic for extracting metadata from Ecto schema modules.

  Provides mechanisms to:
  - Extract default values for various module attributes
  - Generate module-specific metadata
  - Transform schema information into user-friendly configurations

  Supports a wide range of configuration options for customizing UI generation.
  """

  use AuroraUix.Parsers.ParserCore

  @doc """
  Extracts schema metadata and merges common options.

  ## PARAMETERS
  - `parsed_opts` (`map`) - Map (accumulator) for parsed options.
  - `module` (`module`) - Schema module to be used for gathering field information.
  - `opts` (`Keyword.t()`) - Configuration options with keys:
    ### Common opts
    - `actions` - List of {position, function} tuples for UI actions
    - `add_actions` - Additional actions to append
    - `fields` -  Fields to be used, overrides the default list.
      The default list is created with all the fields found in the module, excluding
      the redacted fields.
    - `link` -  The link name to use for paths. By default, is the same as source.
    - `name` -  Name of the schema. By default, uses the last part of the module name.
    - `remove` -  List of fields to be remove from the list.
      trying to remove non-existing fields will log a warning, but no error will be raised.
    - `remove_actions` -  Removes actions from the current list.
    - `source` : Key of the data. By default, resolves the source from the schema source value.
      Uses the function __schema__/1 passing :source as the argument.
    - `sub_title` -  Subtitle for the view, a :hide value will disallow its generation.
    - `template` -  Overrides the module that handles the generation.
      By default, uses AuroraUixWeb.AuroraTemplate, which is a sophisticated and highly opinionated template.
      There is also the AuroraUixWeb.PhoenixTemplate, which resembles the phoenix ui.
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
    iex> alias AuroraUix.Parsers.Common
    iex> defmodule AuroraUix.GeneralLedger.Account do
    ...>    use Ecto.Schema
    ...>    schema "accounts" do
    ...>      field :description, :string
    ...>      field :number, :string
    ...>      timestamps()
    ...>    end
    ...>  end
    iex> parsed = Common.parse(%{}, AuroraUix.GeneralLedger.Account, [])
    iex> parsed.name == "Account" # Name is taken from last part of the schema module name
    true
    iex> parsed.title == "Accounts" # Uses the capitalized schema source as the title.

    iex> alias AuroraUix.Parsers.Common
    iex> defmodule AuroraUix.GeneralLedger.AccountReceivable do
    ...>   use Ecto.Schema
    ...>   schema "account_receivables" do
    ...>     field :description, :string
    ...>     field :amount, :float
    ...>     timestamps()
    ...>   end
    ...> end
    iex> parsed = Common.parse(%{}, AuroraUix.GeneralLedger.AccountReceivable, [])
    iex> parsed.title == "Account Receivables"  # Uses the capitalized schema source as the title
  """
  @spec parse(map, module, Keyword.t()) :: map
  def parse(parsed_opts, module, opts) do
    parsed_opts
    |> add_opt(module, opts, :module)
    |> add_opt(module, opts, :module_name)
    |> add_opt(module, opts, :link)
    |> add_opt(module, opts, :name)
    |> add_opt(module, opts, :source)
    |> add_opt(module, opts, :title)
  end

  @doc """
  Resolves default values for schema-derived properties.

  ### Parameters
    - `module` (`module`) -  Schema module.
    - `key` (`atom`) -  Key value to produce the value from.

  """
  @spec default_value(module, atom) :: any

  def default_value(module, :module) do
    module
    |> Module.split()
    |> List.last()
    |> Macro.underscore()
  end

  def default_value(module, :module_name) do
    module
    |> Module.split()
    |> List.last()
  end

  def default_value(module, :name) do
    module
    |> Module.split()
    |> List.last()
    |> capitalize()
  end

  def default_value(module, :source), do: module.__schema__(:source)

  def default_value(module, :link), do: module.__schema__(:source)

  def default_value(module, :title) do
    :source
    |> module.__schema__()
    |> capitalize()
  end
end
