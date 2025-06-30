defmodule Aurora.Uix.Layout.Options do
  @moduledoc """
  Provides utilities for retrieving layout options based on the current assigns context.

  ## Key features

    * Delegates option retrieval to tag-specific modules (e.g., `Aurora.Uix.Layout.ShowOptions`) when applicable.
    * Logs warnings and returns `{:not_found, option}` for unsupported tags or missing options.
    * Centralizes error reporting for unknown or unimplemented options.

  ## Key constraints

    * Expects assigns to contain `_auix` and `_path` keys with appropriate structure.
    * Only delegates to tag-specific modules when the tag is recognized.
    * Does not implement option handling for all possible tags; unrecognized tags will log a warning.

  """

  alias Aurora.Uix.Layout.ShowOptions
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
  def get(%{_auix: %{_path: %{tag: :show}}} = assigns, option) do
    ShowOptions.get(assigns, option)
  end

  def get(%{_auix: %{_path: %{tag: tag, name: name}}}, option) do
    Logger.warning("Option #{option} is not implemented for tag: #{tag}: #{name}")
    {:not_found, option}
  end

  def get(_assigns, option) do
    report_error(option)
  end

  @doc """
  Logs a warning and returns `{:not_found, option}` for unimplemented or unknown options.

  ## Parameters

    - `option` (atom()) - The option key that was not found or is not implemented.

  ## Returns

    - `{:not_found, atom()}` - Always returns a tuple indicating the option is not found.

  """
  @spec report_error(atom()) :: {:not_found, atom()}
  def report_error(option) do
    Logger.warning("Option #{option} is not implemented.")
    {:not_found, option}
  end
end
