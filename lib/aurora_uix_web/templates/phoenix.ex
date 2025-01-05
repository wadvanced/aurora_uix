defmodule AuroraUixWeb.Templates.Phoenix do
  @moduledoc """
  A module for generating basic HEEx templates for different UI component types.

  This module provides a single function, `generate/2`,
  which creates HEEx template fragments based on the specified type.
  Currently, it supports the following types:

  - `:list`: Generates a template for a list.
  - `:card`: Generates a template for a card.
  - `:form`: Generates a template for a form.

  ## Examples

  ```elixir
  iex> AuroraUixWeb.Templates.Base.generate(:list, %{})
  # => quote do: ~H"<h1>Phoenix Template</h1>list"

  iex> AuroraUixWeb.Templates.Base.generate(:card, %{})
  # => quote do: ~H"<h1>Phoenix Template</h1>card"

  iex> AuroraUixWeb.Templates.Base.generate(:form, %{})
  # => quote do: ~H"<h1>Phoenix Template</h1>form"
  """

  @behaviour AuroraUixWeb.Template

  @doc """
  Generates a basic HEEx template fragment for the specified type.

  ## Parameters

  - `type` (`atom`): Specifies the type of template to generate.
    Supported values: `:list`, `:card`, `:form`.

  - `opts` (`map`): A map of options (currently unused in this implementation).

  ## Returns

  - (`Macro.t()`): A quoted HEEx template corresponding to the specified type.

  ## Examples

  ```elixir
  generate(:list, %{})
  # => quote do: ~H"<h1>Phoenix Template</h1>list"

  generate(:card, %{})
  # => quote do: ~H"<h1>Phoenix Template</h1>card"

  generate(:form, %{})
  # => quote do: ~H"<h1>Phoenix Template</h1>form"
  """
  @spec generate(atom, Keyword.t()) :: Macro.t()
  def generate(:list, _opts) do
    quote do
      ~H"""
      <h1>Phoenix Template</h1>
      list
      """
    end
  end

  def generate(:card, _opts) do
    quote do
      ~H"""
      <h1>Phoenix Template</h1>
      card
      """
    end
  end

  def generate(:form, _opts) do
    quote do
      ~H"""
      <h1>Phoenix Template</h1>
      form
      """
    end
  end
end
