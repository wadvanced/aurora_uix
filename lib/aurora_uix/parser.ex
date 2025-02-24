defmodule AuroraUix.Parser do
  @moduledoc """
  Processes the options and produces a map for further rendering.
  """

  alias AuroraUix.Parsers.Common
  alias AuroraUix.Parsers.IndexParser

  @callback default_value(module :: module, key :: atom) :: any

  @doc """
  ## Parameters
    - `module` (module): Schema module to be used for gathering field information.
    - `opts` (Keyword.t()): List of options, the available ones depends on the type of view.
    See `AuroraUixWeb.Uix.CreateUI.auix_create_ui/1` docs for type and opts details.

  ## Parsed output
    A map with the following content is produced:

  ### Common keys
   - `:module`: Last part of the name of the schema module. For schema `AuroraUixDemo.GeneralLedger.Account` then %{module: "account"}.
   - `:module_name`: Last part of the name of the schema module. For schema `AuroraUixDemo.GeneralLedger.AccountReceivable` then %{module_name: "AccountReceivable"}
   - `:name`: Capitalize schema module. For schema `AuroraUixDemo.GeneralLedger.Account` then %{name: "Account"}
   - `:source`: The table name of the schema. For example: %{source: "account_receivables"}
   - `:title`: The pluralize name of the module. For schema `AuroraUixDemo.GeneralLedger.AccountReceivable` then %{title: "Account receivables"}.
   - `:fields`: List of the schema fields

  ### Index keys
   - `:rows`: Keys path for accessing the socket list of elements. For schema `AuroraUixDemo.GeneralLedger.AccountReceivable`
    the %{rows: [:streams, :account_receivables]

  ### Example
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
      source: "my_schemas"
    }
  """
  @spec parse(module, Keyword.t()) :: map
  def parse(module, opts \\ []) do
    %{}
    |> Common.parse(module, opts)
    |> IndexParser.parse(module, opts)
  end
end
