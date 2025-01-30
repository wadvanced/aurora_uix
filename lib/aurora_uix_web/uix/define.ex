defmodule AuroraUixWeb.Uix.Define do
  @moduledoc """
  Enables the definition of views and components.
  """

  import AuroraUixWeb.Uix, only: [__auix_options__: 1, __auix_do__: 2]

  alias AuroraUixWeb.Uix.Define

  @spec layout(atom, atom, Keyword.t(), Keyword.t() | nil) :: Macro.t()
  defmacro layout(name, type, opts \\ [], do_block \\ nil) do
    quote do
      Define.__auix_layout__(
        __MODULE__,
        unquote(name),
        unquote(type),
        unquote(__auix_options__(opts))
      )

      unquote(__auix_do__(opts, do_block))
    end
  end

  @doc """
  Handles the creation of layouts
  """
  @spec __auix_layout__(module, atom, atom, Keyword.t()) :: :ok
  def __auix_layout__(_module, _name, _type, _opts) do
    :ok
  end
end
