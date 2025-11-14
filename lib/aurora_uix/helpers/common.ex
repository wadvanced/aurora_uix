defmodule Aurora.Uix.Helpers.Common do
  @moduledoc """
  Common helper functions for Aurora.Uix.
  """

  @doc """
  Safely converts a binary to an existing atom.

  ## Parameters
  - `name` (`term()` | `nil`) - The name to convert to an atom.

  ## Returns
  `atom()` | `nil` - The existing atom if it exists, otherwise nil.

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
  Safely converts a binary to an atom.
  ## Parameters
  - `name` (`term()` | `nil`) - The name to convert to an atom.
  ## Returns
  `atom()` | `nil` - The atom if conversion is successful, otherwise nil.
  """
  @spec safe_atom(term() | nil) :: atom() | nil
  def safe_atom(name) when is_binary(name), do: String.to_atom(name)
  def safe_atom(name) when is_atom(name), do: name
  def safe_atom(_name), do: nil

  @doc """
  Capitalizes a given string by converting underscores to spaces and capitalizing each word.

  ## Parameters
  - `string` (`binary()` | `nil`) - The string to capitalize.

  ## Returns
  `binary()` - The capitalized string.
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
