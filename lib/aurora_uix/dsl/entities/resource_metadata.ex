defmodule Aurora.Uix.Dsl.Entity.ResourceMetadata do
  @moduledoc """
  Spark entity target for resource metadata declarations.

  ## Key Features

  - Struct shape for `auix_resource_metadata` blocks
  - Entity declaration consumed by the Spark extension

  ## Key Constraints

  - Declaration only; lowering into `%Aurora.Uix.Resource{}` happens in transformers
  """

  defstruct [
    :name,
    :schema,
    :context,
    :ash_resource,
    :ash_actor_assign,
    :actor_assign,
    :type,
    :order_by,
    :renderers,
    __spark_metadata__: nil
  ]

  @type t :: %__MODULE__{
          name: atom() | nil,
          schema: module() | nil,
          context: module() | nil,
          ash_resource: module() | nil,
          ash_actor_assign: atom() | nil,
          actor_assign: atom() | nil,
          type: atom() | nil,
          order_by: atom() | keyword() | list() | nil,
          renderers: map() | nil,
          __spark_metadata__: Spark.Dsl.Entity.spark_meta() | nil
        }

  @doc false
  @spec __entity__() :: Spark.Dsl.Entity.t()
  def __entity__ do
    %Spark.Dsl.Entity{
      name: :resource_metadata,
      describe: "Declares UI metadata for one resource",
      args: [:name],
      identifier: :name,
      target: __MODULE__,
      schema: [
        name: [type: :atom, required: true],
        schema: [type: :module, required: false],
        context: [type: :module, required: false],
        ash_resource: [type: :module, required: false],
        ash_actor_assign: [type: :atom, required: false],
        actor_assign: [type: :atom, required: false],
        type: [type: {:in, [:ash, :ctx]}, required: false],
        order_by: [type: {:or, [:atom, :keyword_list, {:list, :atom}]}, required: false],
        renderers: [type: {:map, :atom, {:or, [:atom, {:fun, 1}]}}, required: false]
      ]
    }
  end
end
