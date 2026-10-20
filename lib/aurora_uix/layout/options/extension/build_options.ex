defmodule Aurora.Uix.Layout.Options.Extension.BuildOptions do
  @moduledoc """
  Spark transformer that builds an option set's `options/0` and `get/2`.

  ## Key Features
  - Sets each option's layout type from `use Aurora.Uix.Layout.Options, layout_type: ...`.

  ## Key Constraints
  - An option set declares each option once, with a valid `Spark.Options` type.
  """

  use Spark.Dsl.Transformer

  alias Aurora.Uix.Layout.Options, as: LayoutOptions
  alias Aurora.Uix.Layout.Options.Option
  alias Spark.Dsl.Entity
  alias Spark.Dsl.Transformer
  alias Spark.Error.DslError

  @doc false
  @spec transform(map()) :: {:ok, map()}
  def transform(dsl_state) do
    module = Transformer.get_persisted(dsl_state, :module)
    layout_type = Module.get_attribute(module, :auix_layout_type)

    declared = Transformer.get_entities(dsl_state, [:auix_layout_options])
    :ok = validate_options(declared, module)
    options = Enum.map(declared, &%{&1 | layout_type: layout_type, __spark_metadata__: nil})

    {:ok, Transformer.eval(dsl_state, [], LayoutOptions.options_code(layout_type, options))}
  end

  ## PRIVATE

  @spec validate_options([Option.t()], module()) :: :ok
  defp validate_options(options, module) do
    case options -- Enum.uniq_by(options, & &1.name) do
      [] ->
        Enum.each(options, &validate_type(&1, module))

      [option | _rest] ->
        raise DslError,
          module: module,
          path: [:option, option.name],
          location: Entity.anno(option),
          message: "option #{inspect(option.name)} is declared more than once"
    end
  end

  @spec validate_type(Option.t(), module()) :: :ok
  defp validate_type(option, module) do
    case Spark.Options.validate_type(option.type) do
      {:ok, _type} ->
        :ok

      {:error, message} ->
        raise DslError,
          module: module,
          path: [:option, option.name],
          location: Entity.anno(option),
          message: "option #{inspect(option.name)}: #{message}"
    end
  end
end
