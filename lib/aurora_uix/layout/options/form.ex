defmodule Aurora.Uix.Layout.Options.Form do
  @moduledoc """
  Handles retrieval of options specific to `:form` and `:index` layout tags for edit and new resource actions.

  ## Key features

    * Retrieves options for form layouts, including dynamic and static edit/new titles and subtitles.
    * Delegates fallback option retrieval and error reporting to `Aurora.Uix.Layout.Options`.
    * Supports function-based, binary, and default title/subtitle resolution for edit and new actions.

  ## Key constraints

    * Expects assigns to contain `auix` and `layout_tree` keys with appropriate structure.
    * Only processes options relevant to the `:form`, `:show`, and `:index` tags.

  ## Options

    * `:edit_title` - The title for the edit form.
      - Accepts a `binary()` (static title) or a function of arity 1 that receives assigns and returns a Phoenix.LiveView.Rendered.
      - Default: `"Edit {name}"`, where `{name}` is the resource name.

    * `:edit_subtitle` - The subtitle for the edit form.
      - Accepts a `binary()` or a function of arity 1 that receives assigns and returns a Phoenix.LiveView.Rendered.
      - Default: `"Use this form to manage <strong>{title}</strong> records in your database"`, where `{title}` is the resource title.

    * `:new_title` - The title for the new resource form (when in `:index` context).
      - Accepts a `binary()` or a function of arity 1 that receives assigns and returns a Phoenix.LiveView.Rendered.
      - Default: `"New {name}"`, where `{name}` is the resource name.

    * `:new_subtitle` - The subtitle for the new resource form (when in `:index` context).
      - Accepts a `binary()` or a function of arity 1 that receives assigns and returns a Phoenix.LiveView.Rendered.
      - Default: `"Creates a new <strong>{name}</strong> record in your database"`, where `{name}` is the resource name.

  For additional option behaviors and rendering details, see `Aurora.Uix.Layout.Options`.
  """

  use Aurora.Uix.Layout.Options, :form
  alias Aurora.Uix.Layout.Options, as: LayoutOptions

  ## PRIVATE
  # Returns default values for supported options, otherwise delegates error.
  @spec get_default(map(), atom()) :: {:ok, term()} | {:not_found, atom()}
  defp get_default(%{auix: %{name: name}} = assigns, :edit_title),
    do: {:ok, LayoutOptions.render_binary(assigns, "Edit #{name}")}

  defp get_default(%{auix: %{title: title}} = assigns, :edit_subtitle),
    do:
      {:ok,
       LayoutOptions.render_binary(
         assigns,
         "Use this form to manage <strong>#{title}</strong> records in your database"
       )}

  defp get_default(%{auix: %{name: name}} = assigns, :new_title),
    do: {:ok, LayoutOptions.render_binary(assigns, "New #{name}")}

  defp get_default(%{auix: %{name: name}} = assigns, :new_subtitle),
    do:
      {:ok,
       LayoutOptions.render_binary(
         assigns,
         "Creates a new <strong>#{name}</strong> record in your database"
       )}

  defp get_default(_assigns, option), do: {:not_found, option}
end
