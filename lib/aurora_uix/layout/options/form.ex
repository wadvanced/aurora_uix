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

  @doc """
  Retrieves a form layout option from assigns.

  Looks up the given option in the assigns' configuration for the relevant tag.
  Supports both static and function-based values for `:edit_title`, `:edit_subtitle`, `:new_title`, and `:new_subtitle`.
  Falls back to defaults or delegates error reporting to `LayoutOptions` for unsupported options.

  ## Parameters

    - `assigns` (map()) - Assigns map. Must contain `auix` and `layout_tree` with appropriate tag.
    - `option` (atom()) - The option key to retrieve.

  ## Returns

    - `{:ok, term()}` - The value of the requested option.
    - `{:not_found, atom()}` - Indicates the option is not supported.

  ## Examples

      iex> assigns = %{auix: %{name: "Product", layout_tree: %{tag: :form, opts: [edit_title: "Edit Product"]}}}
      iex> Aurora.Uix.Layout.Options.Form.get(assigns, :edit_title)
      {:ok, "Edit Product"}

      iex> assigns = %{auix: %{name: "Product", layout_tree: %{tag: :form, opts: []}}}
      iex> Aurora.Uix.Layout.Options.Form.get(assigns, :edit_title)
      {:ok, "Edit Product"}

      iex> assigns = %{auix: %{title: "Product", layout_tree: %{tag: :form, opts: []}}}
      iex> Aurora.Uix.Layout.Options.Form.get(assigns, :edit_subtitle)
      {:ok, "Use this form to manage <strong>Product</strong> records in your database"}

      iex> assigns = %{auix: %{layout_tree: %{tag: :index, name: "Product"}}}
      iex> Aurora.Uix.Layout.Options.Form.get(assigns, :new_title)
      {:ok, "New Product"}

      iex> Aurora.Uix.Layout.Options.Form.get(assigns, :unknown_option)
      {:not_found, :unknown_option}

  """
  @spec get(map(), atom()) :: {:ok, term()} | {:not_found, atom()}
  def get(%{auix: %{layout_tree: %{tag: :form, opts: opts}}} = assigns, option) do
    if Keyword.has_key?(opts, option),
      do: get_option(assigns, opts[option], option),
      else: get_default(assigns, option)
  end

  def get(_assigns, option), do: {:not_found, option}

  ## PRIVATE

  # Resolves function or binary values for form titles/subtitles, otherwise delegates error.
  @spec get_option(map(), term(), atom()) :: {:ok, term()} | {:not_found, atom()}
  defp get_option(assigns, value, option)
       when is_function(value, 1) and
              option in [:edit_title, :edit_subtitle, :new_title, :new_subtitle],
       do: {:ok, value.(assigns)}

  defp get_option(assigns, value, option)
       when is_binary(value) and
              option in [:edit_title, :edit_subtitle, :new_title, :new_subtitle],
       do: {:ok, LayoutOptions.render_binary(assigns, value)}

  defp get_option(_assigns, _value, option), do: {:not_found, option}

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
