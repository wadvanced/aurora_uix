defmodule Aurora.Uix.Helpers.Common do
  @moduledoc """
  Provides utility functions for string and atom conversion.
  """

  @doc """
  Safely converts a binary to an existing atom without raising an exception.

  Returns the atom if it exists in the current runtime, otherwise returns nil.
  If the input is already an atom, returns it unchanged.
  Any other input returns nil.

  ## Parameters
  - `name` (term() | nil) - The name to convert to an atom.

  ## Returns
  atom() | nil - The existing atom if it exists, otherwise nil.
  """
  @spec safe_existing_atom(term() | nil) :: atom() | nil
  def safe_existing_atom(name) when is_binary(name) do
    String.to_existing_atom(name)
  catch
    _ -> nil
  end

  def safe_existing_atom(name) when is_atom(name), do: name

  def safe_existing_atom(_name), do: nil

  @doc """
  Safely converts a binary to an atom, creating it if necessary.

  If the input is already an atom, returns it unchanged.
  Any other input returns nil.

  ## Parameters
  - `name` (term() | nil) - The name to convert to an atom.

  ## Returns
  atom() | nil - The atom if conversion is successful, otherwise nil.
  """
  @spec safe_atom(term() | nil) :: atom() | nil
  def safe_atom(name) when is_binary(name), do: String.to_atom(name)
  def safe_atom(name) when is_atom(name), do: name
  def safe_atom(_name), do: nil

  @doc """
  Capitalizes a given string by converting underscores to spaces and capitalizing each word.

  Processes the input by converting it to a string, applying `Macro.underscore/1`,
  replacing consecutive underscores with a single underscore, replacing underscores
  with spaces, splitting by spaces, and capitalizing each word.

  Empty or nil input returns an empty string.

  ## Parameters
  - `string` (binary() | nil) - The string to capitalize.

  ## Returns
  binary() - The capitalized string.

  ## Examples
  ```elixir
  iex> capitalize("hello_world")
  "Hello World"

  iex> capitalize("HelloWorld")
  "Hello World"

  iex> capitalize(nil)
  ""
  ```
  """
  @spec capitalize(binary() | nil) :: binary()
  def capitalize(nil), do: ""

  def capitalize(string) do
    string
    |> to_string()
    |> Macro.underscore()
    |> String.replace("__", "_")
    |> String.replace("_", " ")
    |> String.split(" ")
    |> Enum.map_join(" ", &String.capitalize/1)
  end
end
