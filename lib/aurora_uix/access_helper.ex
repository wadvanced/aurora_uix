defmodule Aurora.Uix.AccessHelper do
  @moduledoc """
  Implements the `Access` behaviour for structs.

  This helper module provides a simple way to make a struct compliant with the `Access`
  behaviour by delegating the implementation of `fetch/2`, `get_and_update/3`, and `pop/2`
  to this module.

  ## Usage

  To use this helper, you just need to `use Aurora.Uix.AccessHelper` in your module definition.

  ```elixir
  defmodule MyStruct do
    @enforce_keys [:foo]
    defstruct [:foo, :bar]

    use Aurora.Uix.AccessHelper
  end
  ```

  With the above setup, `MyStruct` will automatically implement the `Access` behaviour:

  ```elixir
  iex> my_struct = %MyStruct{foo: "hello", bar: "world"}
  iex> my_struct[:foo]
  "hello"

  iex> get_in(my_struct, [:bar])
  "world"

  iex> put_in(my_struct, [:foo], "updated")
  %MyStruct{foo: "updated", bar: "world"}
  ```
  """
  alias Aurora.Uix.AccessHelper

  @doc """
  Injects the `Access` behaviour implementation into the calling module.

  When you `use Aurora.Uix.AccessHelper`, it sets up the module to behave
  like a map for the purpose of the `Access` protocol.
  """
  defmacro __using__(_opts) do
    quote do
      alias Aurora.Uix.AccessHelper
      @behaviour Access
      @before_compile AccessHelper
    end
  end

  @doc false
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
  Fetches the value for a specific key from a struct.

  This function is the implementation of `Access.fetch/2`. It returns `{:ok, value}`
  if the key is present in the struct, or `:error` otherwise.

  ## Parameters

  - `struct` (`struct()`) - The struct to fetch the value from.
  - `key` (`atom()`) - The key to fetch.

  ## Returns

  `{:ok, term()} | :error` - The result of the fetch operation.
  """
  @spec fetch(struct(), atom()) :: {:ok, any()} | :error
  def fetch(field, key) do
    case Map.has_key?(field, key) do
      true -> {:ok, Map.get(field, key)}
      _ -> :error
    end
  end

  @doc """
  Gets and updates a value in a struct.

  This function is the implementation of `Access.get_and_update/3`.

  ## Parameters

  - `data` (`map()`) - The struct to update.
  - `key` (`atom()`) - The key to get and update.
  - `function` (`function()`) - A function that receives the current value and returns either
    `{current_value, new_value}` or `:pop`.

  ## Returns

  `{any(), map()}` - A tuple with the original value and the updated struct.
  """
  @spec get_and_update(map(), atom(), (any() -> {any(), any()} | :pop)) :: {any(), map()}
  def get_and_update(data, key, function) do
    data
    |> Map.get(key)
    |> then(fn value -> function.(value) end)
    |> then(&maybe_update_data(data, key, &1))
  end

  @doc """
  Pops a value from a struct.

  This function is the implementation of `Access.pop/2`. It returns the value
  associated with the key and the struct without that key.

  ## Parameters

  - `data` (`map()`) - The struct to pop the value from.
  - `key` (`atom()`) - The key to pop.

  ## Returns

  `{any(), map()}` - A tuple with the popped value and the updated struct.
  """
  @spec pop(map(), atom()) :: {any(), map()}
  def pop(data, key) do
    if Map.has_key?(data, key) do
      {Map.get(data, key), Map.delete(data, key)}
    else
      {nil, data}
    end
  end

  ## PRIVATE

  @spec maybe_update_data(map(), term(), {any(), any()} | :pop) :: {any(), map()}
  defp maybe_update_data(data, key, {current_value, new_value}) do
    {current_value, Map.put(data, key, new_value)}
  end

  defp maybe_update_data(data, key, :pop) do
    {Map.get(data, key), Map.delete(data, key)}
  end
end
