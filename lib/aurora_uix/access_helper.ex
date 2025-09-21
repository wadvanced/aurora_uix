defmodule Aurora.Uix.AccessHelper do
  alias Aurora.Uix.AccessHelper

  defmacro __using__(_opts) do
    quote do
      alias Aurora.Uix.AccessHelper
      @behaviour Access
      @before_compile AccessHelper
    end
  end

  defmacro __before_compile__(env) do
    module = env.module

    quote do
      @impl Access
      def fetch(%unquote(module){} = struct, key), do: AccessHelper.fetch(struct, key)

      @impl Access
      def get_and_update(data, key, function),
        do: AccessHelper.get_and_update(data, key, function)

      @impl Access
      def pop(data, key), do: AccessHelper.pop(data, key)
    end
  end

  @doc """
  Implements `Access.fetch/2` for the field struct.
  """
  @spec fetch(module(), atom()) :: any()
  def fetch(field, key) do
    case Map.has_key?(field, key) do
      true -> {:ok, Map.get(field, key)}
      _ -> :error
    end
  end

  @doc """
  Implements `Access.get_and_update/3` for the field struct.
  """
  @spec get_and_update(map(), atom(), (any() -> {any(), any()} | :pop)) :: {any(), map()}
  def get_and_update(data, key, function) do
    data
    |> Map.get(key)
    |> then(fn value -> function.(value) end)
    |> then(&maybe_update_data(data, key, &1))
  end

  @doc """
  Implements `Access.pop/2` for the field struct.
  """
  @spec pop(map(), atom()) :: {any(), map()}
  def pop(data, key) do
    if Map.has_key?(data, key) do
      {Map.get(data, key), Map.delete(data, key)}
    else
      {nil, data}
    end
  end

  @spec maybe_update_data(map(), term(), tuple()) :: tuple()
  defp maybe_update_data(data, key, {current_value, new_value}) do
    {current_value, Map.put(data, key, new_value)}
  end

  defp maybe_update_data(data, key, :pop) do
    {Map.get(data, key), Map.delete(data, key)}
  end
end
