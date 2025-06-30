defmodule Aurora.Uix.Layout.Options do
  @moduledoc """
  Provides utilities for retrieving layout options based on the current assigns context.

  ## Key features
    - Delegates option retrieval to tag-specific modules (e.g., `ShowOptions`) when applicable.
    - Logs warnings and returns `{:not_found, option}` for unsupported tags or missing options.

  """

  alias Aurora.Uix.Layout.ShowOptions
  require Logger

  @doc """
  Retrieves a layout option for the given assigns and option key.

  Delegates to tag-specific option modules when the tag is recognized. Logs a warning and returns
  `{:not_found, option}` for unsupported tags or missing options.

  ## Parameters

    - `assigns` (map()) - Assigns map containing the `_auix` and `_path` keys.
    - `option` (atom()) - The option key to retrieve.

  ## Returns

    - `{:ok, term()}` - The value of the requested option.
    - `{:not_found, atom()}` - Indicates the option or tag is not supported.
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

  @spec report_error(atom()) :: {:not_found, atom()}
  def report_error(option) do
    Logger.warning("Option #{option} is not implemented.")
    {:not_found, option}
  end
end
