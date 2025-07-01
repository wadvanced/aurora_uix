defmodule Aurora.Uix.Layout.Options.Page do
  @moduledoc """
  Handles retrieval of options specific to `:show` layout tags.

  ## Key features

    * Retrieves options for `:show` layouts, including dynamic and static page titles and subtitles.
    * Delegates fallback option retrieval and error reporting to `Aurora.Uix.Layout.Options`.
    * Supports function-based, binary, and default page title/subtitle resolution.

  ## Key constraints

    * Expects assigns to contain `auix` and `layout_tree` keys with appropriate structure.
    * Only processes options relevant to the `:show` tag.

  ## Options

    * `:page_title` - The page title for the show layout.
      - Accepts a `binary()` (static title) or a function of arity 1 that receives assigns and expected to return a Phoenix.LiveView.Rendered.
      - Default: `"{name} Details"`, where `{name}` is the capitalized schema name.

    * `:page_subtitle` - The page subtitle for the show layout.
      - Accepts a `binary()` or a function of arity 1 that receives assigns and expected to return a Phoenix.LiveView.Rendered.
      - Default: `"Detail"`
  """

  alias Aurora.Uix.Layout.Options, as: LayoutOptions

  @doc """
  Retrieves a show layout option from assigns.

  Looks up the given option in the assigns' `auix.layout_tree.opts` if the tag is `:show`.
  Supports both static and function-based values for `:page_title` and `:page_subtitle`.
  Falls back to defaults or delegates error reporting to `LayoutOptions` for unsupported options.

  ## Parameters
  - `assigns` (map()) - Assigns map. Must contain `auix` and `layout_tree` with `:show` tag.
  - `option` (atom()) - The option key to retrieve.

  ## Returns
  - `{:ok, term()}` - The value of the requested option.
  - `{:not_found, atom()}` - Indicates the option is not supported.

  ## Examples

      iex> assigns = %{auix: %{name: "Product", layout_tree: %{tag: :show, opts: [page_title: "Custom"]}}}
      iex> Aurora.Uix.Layout.Options.Page.get(assigns, :page_title)
      {:ok, "Custom"}

      iex> assigns = %{auix: %{name: "Product", layout_tree: %{tag: :show, opts: []}}}
      iex> Aurora.Uix.Layout.Options.Page.get(assigns, :page_title)
      {:ok, "Product"}

      iex> assigns = %{auix: %{name: "Product", layout_tree: %{tag: :show, opts: []}}}
      iex> Aurora.Uix.Layout.Options.Page.get(assigns, :page_subtitle)
      {:ok, "Details"}

      iex> Aurora.Uix.Layout.Options.Page.get(assigns, :unknown_option)
      {:not_found, :unknown_option}

  """
  @spec get(map(), atom()) :: {:ok, term()} | {:not_found, atom()}
  def get(%{auix: %{layout_tree: %{tag: tag, opts: opts}}} = assigns, option)
      when tag in [:show, :index] do
    if Keyword.has_key?(opts, option),
      do: get_option(assigns, opts[option], option),
      else: get_default(assigns, option)
  end

  def get(_assigns, option), do: {:not_found, option}

  ## PRIVATE

  # Resolves function or binary values for page title/subtitle, otherwise delegates error.
  @spec get_option(map(), term(), atom()) :: {:ok, term()} | {:not_found, atom()}
  defp get_option(assigns, value, option)
       when is_function(value, 1) and option in [:page_title, :page_subtitle],
       do: {:ok, value.(assigns)}

  defp get_option(assigns, value, option)
       when is_binary(value) and option in [:page_title, :page_subtitle],
       do: {:ok, LayoutOptions.render_binary(assigns, value)}

  defp get_option(_assigns, _value, option), do: {:not_found, option}

  # Returns default values for supported options, otherwise delegates error.
  @spec get_default(map(), atom()) :: {:ok, term()} | {:not_found, atom()}
  defp get_default(%{auix: %{layout_tree: %{tag: :show}, name: name}} = assigns, :page_title),
    do: {:ok, LayoutOptions.render_binary(assigns, "#{name}")}

  defp get_default(%{auix: %{layout_tree: %{tag: :show}}} = assigns, :page_subtitle),
    do: {:ok, LayoutOptions.render_binary(assigns, "Details")}

  defp get_default(%{auix: %{layout_tree: %{tag: :index}, title: title}} = assigns, :page_title),
    do: {:ok, LayoutOptions.render_binary(assigns, "Listing #{title}")}

  defp get_default(_assigns, option), do: {:not_found, option}
end
