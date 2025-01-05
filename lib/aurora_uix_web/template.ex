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

  @doc """
  Validates that the given module implements the current behaviour (`#{__MODULE__}`).

  This function checks two things:
  1. The module has declared the `#{__MODULE__}` behaviour via the `@behaviour` attribute.
  2. The module exports the required functions.

  If either of these conditions is not met, it raises an `ArgumentError`.

  ## Parameters

    - `module` (`module`): The module to validate.

  ## Returns

    - (`module`): The same module, if it is valid.

  ## Raises

    - `ArgumentError`: If the module does not implement the required behaviour or does not define the `generate/2` function.

  ## Examples

    ```elixir
    defmodule ValidModule do
      @behaviour AuroraUixWeb.Template
      def generate(:example, _opts), do: :ok
    end

    defmodule InvalidModule do
      def generate(:example, _opts), do: :ok
    end

    AuroraUixWeb.Template.validate(ValidModule)
    # => ValidModule

    AuroraUixWeb.Template.validate(InvalidModule)
    # => ** (ArgumentError) The InvalidModule does not implement the `AuroraUixWeb.Template` behaviour.
  """
  @spec validate(module) :: module
  def validate(module) do
    valid? =
      module
      |> behaviour_implemented?()
      |> Kernel.and(function_exported?(module, :generate, 2))

    if !valid?,
      do:
        raise(
          ArgumentError,
          "The #{module} does not implement the `#{__MODULE__}` behaviour."
        )

    module
  end

  @spec behaviour_implemented?(module) :: boolean
  defp behaviour_implemented?(module) do
    :attributes
    |> module.__info__()
    |> Keyword.get(:behaviour, [])
    |> Enum.member?(__MODULE__)
  end
end
