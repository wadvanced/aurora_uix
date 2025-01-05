defmodule AuroraUixWeb.Template do
  @moduledoc """
  Templates are expected to implement this behaviour.
  """

  @doc """
  Generates a HEEx code fragment for the specified type and options.

  ## Parameters

  - `type` (`atom`): Specifies the type of UI component to generate.
    The types implemented and supported by the library are: `:list`, `:card`, `:form`.

  - `opts` (`Keyword.t()`): A keyword list of options for customizing the generated HEEx code.
    See the list of available opts in AuroraUixWeb.Uix.define/3.

  ## Returns

  - (`Macro.t()`): The generated HEEx code fragment as a quoted expression.

  ## Examples

  ```elixir
  generate(:list, fields: [:name, :email])
  # => quote do: ~H"<ul><li><%= @name %></li><li><%= @email %></li></ul>"

  generate(:card, title: "User Info", content: ~H"<p><%= @user %></p>")
  # => quote do: ~H"<div class=\"card\"><h1>User Info</h1><p><%= @user %></p></div>"

  """
  @callback generate(type :: atom, opts :: Keyword.t()) :: Macro.t()
end
