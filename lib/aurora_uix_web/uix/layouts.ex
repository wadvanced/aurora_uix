defmodule AuroraUixWeb.Layouts do
  @moduledoc """
  Handles the creation of views based on templates and layouts.
  """

  @doc """
  Handles the creation of view by layouts.
  """
  @spec __auix_layout__(module, atom, atom, Keyword.t()) :: :ok
  def __auix_layout__(_module, _name, _type, _opts) do
    :ok
  end
end
