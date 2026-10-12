defmodule Aurora.Uix.Dsl.Entity.Fields do
  @moduledoc """
  Spark entity target for bulk field declarations.

  ## Key Features

  - Struct shape for `fields` blocks with shared options
  - Key validation through the entity transform

  ## Key Constraints

  - Declaration only; expansion into single fields happens in the lowering transformer
  """

  defstruct [:keys, opts: [], __spark_metadata__: nil]

  @type t :: %__MODULE__{
          keys: [atom()] | nil,
          opts: keyword(),
          __spark_metadata__: Spark.Dsl.Entity.spark_meta() | nil
        }

  @doc false
  @spec __entity__() :: Spark.Dsl.Entity.t()
  def __entity__ do
    %Spark.Dsl.Entity{
      name: :fields,
      describe: "Configures several fields with shared options",
      args: [:keys],
      target: __MODULE__,
      transform: {__MODULE__, :validate_keys, []},
      schema: [
        keys: [type: {:list, :atom}, required: true],
        opts: [type: :keyword_list, required: false, default: []]
      ]
    }
  end

  @doc false
  @spec validate_keys(t()) :: {:ok, t()} | {:error, String.t()}
  def validate_keys(%__MODULE__{keys: [_ | _]} = fields), do: {:ok, fields}
  def validate_keys(%__MODULE__{}), do: {:error, "keys must be a non-empty list of atoms"}
end
