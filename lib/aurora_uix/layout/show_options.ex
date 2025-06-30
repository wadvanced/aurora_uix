defmodule Aurora.Uix.Layout.ShowOptions do
  @moduledoc """
  Handles retrieval of options specific to `:show` layout tags.

  ## Key Features
  - Retrieves options for `:show` layouts, including dynamic and static page titles.
  - Delegates fallback option retrieval to `Aurora.Uix.Layout.Options`.
  - Supports function-based, binary, and default page title resolution.

  ## Key Constraints
  - Expects assigns to contain `_auix` and `_path` keys with appropriate structure.
  - Only processes options relevant to the `:show` tag.

  ## Options

  - `:page_title`: Can be a binary or a function with arity 1 that will receive assigns and
      must return a term that implements the String.Chars behaviour.
      The default value is "{name} Details" where {name} is the capitalize name of the schema.
  """

  alias Aurora.Uix.Layout.Options, as: LayoutOptions

  @doc """

  ## Parameters
  - `assigns` (map()) - Assigns map, must contain `_auix` and `_path` with `:show` tag.
  - `option` (atom()) - The option key to retrieve.

  ## Returns
  {:ok, term()} | {:not_found, atom()} - Tuple with the option value or not found.
  """
  @spec get(map(), atom()) :: {:ok, term()} | {:not_found, atom()}
  def get(%{_auix: %{_path: %{tag: :show, opts: opts}}} = assigns, option) do
    if Keyword.has_key?(opts, option),
      do: get_option(assigns, opts[option], option),
      else: get_default(assigns, option)
  end

  ## PRIVATE
  # Page title and subtitle resolution for show layouts and fallback to general options.
  @spec get_option(map(), term(), atom()) :: {:ok, term()} | {:not_found, atom()}

  defp get_option(assigns, title_function, option)
       when is_function(title_function, 1) and option in [:page_title, :page_subtitle],
       do: {:ok, title_function.(assigns)}

  defp get_option(_assigns, title, option)
       when is_binary(title) and option in [:page_title, :page_subtitle],
       do: {:ok, title}

  defp get_option(_assigns, _value, option), do: LayoutOptions.report_error(option)

  defp get_default(%{_auix: %{name: name}}, :page_title), do: {:ok, "#{name} Details"}
  defp get_default(_assigns, :page_subtitle), do: {:ok, "Detail"}
  defp get_default(_assigns, option), do: LayoutOptions.report_error(option)
end
