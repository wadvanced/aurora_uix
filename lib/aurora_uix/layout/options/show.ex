defmodule Aurora.Uix.Layout.Options.Show do
  @moduledoc """
  Handles retrieval of options specific to `:show` layout tags.

  Retrieves options for `:show` layouts, including dynamic and static page titles and subtitles.
  Delegates fallback option retrieval and error reporting to `Aurora.Uix.Layout.Options`.

  ## Options

  * `:page_title` - The page title for the show layout.
    - Accepts a `binary()` (static title) or a function of arity 1 that receives assigns and expected to return a Phoenix.LiveView.Rendered.
    - Default: `"{name} Details"`, where `{name}` is the capitalized schema name.

  * `:page_subtitle` - The page subtitle for the show layout.
    - Accepts a `binary()` or a function of arity 1 that receives assigns and expected to return a Phoenix.LiveView.Rendered.
    - Default: `"Detail"`
  """

  use Aurora.Uix.Layout.Options, :show
  alias Aurora.Uix.Layout.Options, as: LayoutOptions

  ## PRIVATE

  # Returns default values for supported options, otherwise delegates error.
  @spec get_default(map(), atom()) :: {:ok, term()} | {:not_found, atom()}
  defp get_default(%{auix: %{layout_tree: %{tag: :show}, name: name}} = assigns, :page_title),
    do: {:ok, LayoutOptions.render_binary(assigns, "#{name}")}

  defp get_default(%{auix: %{layout_tree: %{tag: :show}}} = assigns, :page_subtitle),
    do: {:ok, LayoutOptions.render_binary(assigns, "Details")}

  defp get_default(_assigns, :record_navigator),
    do: {:ok, [:top, :bottom]}

  defp get_default(_assigns, option), do: {:not_found, option}
end
