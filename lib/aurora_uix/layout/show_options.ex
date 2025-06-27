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
    get_option(assigns, opts[option], option)
  end

  ## PRIVATE
  # Page title resolution for show layouts and fallback to general options.
  @spec get_option(map(), term(), atom()) :: {:ok, term()} | {:not_found, atom()}
  defp get_option(%{_auix: %{name: name}}, nil, :page_title), do: {:ok, "#{name} Details"}

  defp get_option(assigns, page_title_function, :page_title)
       when is_function(page_title_function, 1),
       do: {:ok, page_title_function.(assigns)}

  defp get_option(_assigns, page_title, :page_title) when is_binary(page_title),
    do: {:ok, page_title}

  defp get_option(assigns, _value, option), do: LayoutOptions.get(assigns, option)
end
