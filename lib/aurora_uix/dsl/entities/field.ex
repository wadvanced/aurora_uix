defmodule Aurora.Uix.Dsl.Entity.Field do
  @moduledoc """
  Spark entity target for single field declarations.

  ## Key Features

  - Struct shape for `field` blocks at metadata and layout level
  - Entity declaration sharing the field options schema

  ## Key Constraints

  - Declaration only; application onto parsed fields happens in transformers
  """

  alias Aurora.Uix.Dsl.Schema.FieldOptions

  @field_keys FieldOptions.schema() |> Keyword.keys() |> Kernel.++([:__spark_metadata__])

  defstruct @field_keys

  @type t :: %__MODULE__{
          __spark_metadata__: Spark.Dsl.Entity.spark_meta() | nil
        }

  @doc false
  @spec __entity__() :: Spark.Dsl.Entity.t()
  def __entity__ do
    %Spark.Dsl.Entity{
      name: :field,
      describe: "Configures one field",
      args: [:key],
      identifier: :key,
      target: __MODULE__,
      schema: FieldOptions.schema()
    }
  end
end
