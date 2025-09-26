defmodule Aurora.Uix.BehaviourHelper do
  @moduledoc """
  Provides helper functions for validating behaviour implementations.
  """

  @doc """
  Validates that a module implements a given behaviour.

  It checks if the module implements the behaviour and all its callbacks.
  If the validation fails, it raises an `ArgumentError`.

  ## Parameters
  - `module` (`module()`) - The module to validate.
  - `behaviour` (`module()`) - The behaviour module to check against.

  ## Returns
  `module()` - The validated module if it implements the behaviour.

  ## Raises
  `ArgumentError` - If the module does not implement the behaviour or is missing callbacks.
  """
  @spec validate(module(), module()) :: module()
  def validate(module, behaviour) do
    Code.ensure_compiled!(behaviour)
    Code.ensure_compiled!(module)

    functions_not_exported =
      functions_not_exported(module, behaviour.behaviour_info(:callbacks))

    message =
      case {behaviour_implemented?(module, behaviour), functions_not_exported} do
        {true, []} ->
          nil

        {false, _} ->
          "The #{module} does not implement the `#{behaviour}` behaviour."

        {_, functions_not_exported} ->
          "The #{module} does not implement the following function(s) `#{functions_not_exported}`."
      end

    if message,
      do:
        raise(
          ArgumentError,
          message
        )

    module
  end

  ## PRIVATE

  # Checks if the module implements the behavior
  @spec behaviour_implemented?(module(), module()) :: boolean()
  defp behaviour_implemented?(module, behaviour) do
    :attributes
    |> module.__info__()
    |> Keyword.get(:behaviour, [])
    |> Enum.member?(behaviour)
  end

  # Returns a list of expected functions that are not exported by the module
  @spec functions_not_exported(module(), keyword()) :: list()
  defp functions_not_exported(module, expected_functions) do
    expected_functions
    |> Enum.reject(&function_exported?(module, elem(&1, 0), elem(&1, 1)))
    |> Enum.map(&inspect/1)
  end
end
