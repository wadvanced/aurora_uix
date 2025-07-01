defmodule Aurora.Uix.Layout.Options do
  @moduledoc """
  Provides utilities for retrieving and creating a rendering layout options based on the assigns context.

  ## Key features

    * Delegates option retrieval to tag-specific modules (e.g., `Aurora.Uix.Layout.TitleOptions`) when applicable.
    * Logs warnings and returns `{:not_found, option}` for unsupported tags or missing options.
    * Centralizes error reporting for unknown or unimplemented options.

  ## Key constraints

    * Expects assigns to contain `_auix` and `_path` keys with appropriate structure.
    * Only delegates to tag-specific modules when the tag is recognized.
    * Does not implement option handling for all possible tags; unrecognized tags will log a warning.
  """

  import Phoenix.Component, only: [sigil_H: 2]
  import Phoenix.HTML, only: [raw: 1]

  alias Aurora.Uix.Layout.FormOptions
  alias Aurora.Uix.Layout.TitleOptions
  require Logger

  @doc """
  Retrieves a layout option for the given assigns and option key.

  Delegates to tag-specific option modules when the tag is recognized (e.g., `:show`).
  Logs a warning and returns `{:not_found, option}` for unsupported tags or missing options.

  ## Parameters

    - `assigns` (map()) - Assigns map containing the `_auix` and `_path` keys.
    - `option` (atom()) - The option key to retrieve.

  ## Returns

    - `{:ok, term()}` - The value of the requested option.
    - `{:not_found, atom()}` - Indicates the option or tag is not supported.

  ## Examples

      iex> assigns = %{_auix: %{_path: %{tag: :show}}}
      iex> Aurora.Uix.Layout.Options.get(assigns, :page_title)
      {:ok, "Product Details"}

      iex> assigns = %{_auix: %{_path: %{tag: :edit, name: "resource"}}}
      iex> Aurora.Uix.Layout.Options.get(assigns, :page_title)
      {:not_found, :page_title}

      iex> Aurora.Uix.Layout.Options.get(%{}, :page_title)
      {:not_found, :page_title}

  """
  @spec get(map(), atom()) :: {:ok, term()} | {:not_found, atom()}
  def get(%{_auix: %{_path: %{tag: tag, name: name}}} = assigns, option) do
    with {:not_found, _option} <- TitleOptions.get(assigns, option),
         {:not_found, _option} <- FormOptions.get(assigns, option) do
      Logger.warning("Option #{option} is not implemented for tag: #{tag}: #{name}")
      {:not_found, option}
    end
  end

  @doc """
  Renders a value as a binary in a HEEx template.

  Inserts the value into assigns under the `:auix_option_value` key and renders it.

  ## Parameters

    - `assigns` (map()) - Assigns map for the template.
    - `value` (term()) - Value to render.

  ## Returns

    Phoenix.LiveView.Rendered.t() - Rendered HEEx content containing the value.

  ## Examples

      iex> assigns = %{}
      iex> Aurora.Uix.Layout.Options.render_binary(assigns, "Hello")
      #=> Phoenix.LiveView.Rendered (renders "Hello")
  """
  @spec render_binary(map(), term()) :: Phoenix.LiveView.Rendered.t()
  def render_binary(assigns, value) do
    assigns =
      value
      |> raw()
      |> then(&Map.put(assigns, :auix_option_value, &1))

    ~H"{@auix_option_value}"
  end
end
