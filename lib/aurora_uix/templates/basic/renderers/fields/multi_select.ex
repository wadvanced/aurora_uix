defmodule Aurora.Uix.Templates.Basic.Renderers.MultiSelect do
  @moduledoc """
  Renders a multi-value select (`html_type: :select` with `data.select.multiple`) as a list of
  checkboxes over its options.

  This is the scalar counterpart of `Aurora.Uix.Templates.Basic.Renderers.ManyToMany`, and it exists
  for the same reason: a `<select multiple>` needs a modifier-key gesture that is undiscoverable and
  unusable on touch, conveys state only through a background colour, and has nowhere to host bulk
  controls. The wire format is identical -- every box shares the `parent[field][]` name, so only
  checked values are submitted, exactly as only selected options are.

  Options come straight from the parsed field (`data.select.opts`) through
  `Aurora.Uix.Templates.Basic.Helpers.get_select_options/1`, so both backends reach this renderer
  unchanged: Ctx parses `{:array, Ecto.Enum}` and Ash parses an array attribute whose item type
  carries a `one_of` constraint (or is an `Ash.Type.Enum` module) into the same shape.

  ## Key Features

  - `:form` renders one checkbox per option; the checked boxes are the current value.
  - Submits in the same POST as the parent, under `parent[field][]`.
  - Emits a hidden empty-value sentinel so that de-selecting everything still submits the key, which
    is what makes clearing the last value possible at all.
  - Ships `:default_toggle_all`, a tri-state checkbox beside the label: checked when every option is
    selected, unchecked when none is, and a dash when only some are. Clicking a checked toggle
    clears the selection; clicking it in either other state selects everything.
  - Registers three action groups through `Aurora.Uix.Action` -- `label` (holding the toggle),
    `header` and `footer`, the latter two empty -- so a host adds, replaces or removes controls in
    any of the three strips from the layout DSL field options.
  - `:show` renders only the selected options as a plain, read-only list, with the
    `dt("No options to show")` empty state.

  ## Key Constraints

  - The library is **transport-only** for writes: it renders the input name and forwards the
    submitted list untouched, and never builds a changeset.
  - Because of the sentinel, the submitted list **always** carries one blank entry. The host must
    reject it -- an `Ecto.Enum` array otherwise fails to cast, and Ash rejects the list with
    "no nil values" unless the attribute or argument declares `constraints: [nil_items?: true]`.
  - The toggle rides the parent form's `phx-change="validate"`, identified by `_target`. It must not
    use `phx-click`: a click on a checkbox fires `click` and then `change`, and the trailing change
    would re-validate with the pre-click selection and undo the toggle.
  - Hidden fields never reach this renderer -- `DefaultRenderer` keeps them on its generic clause,
    which renders them as a single `<input type="hidden">`.
  """

  use Aurora.Uix.CoreComponentsImporter
  use Aurora.Uix.GettextResolver

  import Aurora.Uix.Templates.Basic.Components

  alias Aurora.Uix.Templates.Basic.Actions.MultiSelect, as: MultiSelectActions
  alias Aurora.Uix.Templates.Basic.Helpers, as: BasicHelpers

  @doc """
  Renders a multi-value select field.

  ## Parameters
  - `assigns` (map()) - LiveView assigns containing:
    * `:field` (map()) - Field definition with the select options in `:data`.
    * `:auix` (map()) - Aurora UIX context with form, entity and layout configuration.

  ## Returns
  Phoenix.LiveView.Rendered.t() - Rendered multi-value select component.
  """
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(
        %{field: field, auix: %{layout_type: :form, layout_tree: layout_tree} = auix} = assigns
      ) do
    assigns =
      assigns
      |> assign_select()
      |> assign(:input_name, "#{auix.form[field.key].name}[]")
      |> put_in([:auix, :layout_tree, :opts], Map.get(layout_tree, :opts, []))
      |> then(&put_in(&1, [:auix, :multi_select_toggle_state], toggle_state(&1)))
      |> MultiSelectActions.set_actions()

    ~H"""
    <div id={container_id(@field, @auix)} class="auix-multi-select-container">
      <input type="hidden" name={@input_name} value="" />
      <.auix_checkbox_group
        id={options_id(@field, @auix)}
        name={@input_name}
        label={dt(@field.label)}
        options={@select_opts[:options]}
        value={@selected}
        disabled={@field.disabled or @field.readonly}
        empty_message={dt("No options available")}
      >
        <:label_actions>
          <%= for %{function_component: action} <- @auix.multi_select_label_actions do %>
            {action.(%{auix: @auix, field: @field})}
          <% end %>
        </:label_actions>
        <:actions>
          <%= for %{function_component: action} <- @auix.multi_select_header_actions do %>
            {action.(%{auix: @auix, field: @field})}
          <% end %>
        </:actions>
      </.auix_checkbox_group>
      <div class="auix-multi-select-footer-actions" name={"auix-multi-select-footer-actions-#{@field.key}"}>
        <%= for %{function_component: action} <- @auix.multi_select_footer_actions do %>
          {action.(%{auix: @auix, field: @field})}
        <% end %>
      </div>
    </div>
    """
  end

  def render(assigns) do
    assigns =
      assigns
      |> assign_select()
      |> then(&assign(&1, :selected_labels, selected_labels(&1)))

    ~H"""
    <div id={container_id(@field, @auix)} class="auix-multi-select-container">
      <.auix_selected_list
        id={options_id(@field, @auix)}
        label={dt(@field.label)}
        items={@selected_labels}
        empty_message={dt("No options to show")}
      />
    </div>
    """
  end

  ## PRIVATE ##

  # Computes the option list and the selected values, shared by both layout types.
  @spec assign_select(map()) :: map()
  defp assign_select(assigns) do
    assigns
    |> assign(:select_opts, BasicHelpers.get_select_options(assigns))
    |> assign(:selected, selected_values(assigns))
  end

  # Stable id: html_ids embed a global counter and are not stable across test ordering.
  @spec container_id(map(), map()) :: binary()
  defp container_id(%{key: key}, %{layout_type: layout_type}),
    do: "auix-multi-select-#{key}-#{layout_type}"

  # Each checkbox derives its own id from this one. A stable per-input id is what lets LiveView
  # track and patch `checked`; without it, a second toggle-all click appears to do nothing.
  @spec options_id(map(), map()) :: binary()
  defp options_id(field, auix), do: "#{container_id(field, auix)}-options"

  # The values that must render as selected. Submitted params win when present, so an in-flight edit
  # survives re-render; `form[key].value` is deliberately not used, because on Ash the field may
  # still be nil on the first `:edit` render.
  @spec selected_values(map()) :: list()
  defp selected_values(%{field: %{key: key}, auix: auix}) do
    auix
    |> submitted_or_entity_values(key)
    |> List.wrap()
    |> Enum.reject(&(is_nil(&1) or &1 == ""))
  end

  @spec submitted_or_entity_values(map(), atom()) :: term()
  defp submitted_or_entity_values(%{form: %{params: params}} = auix, key) do
    case Map.get(params, to_string(key)) do
      nil -> entity_values(auix, key)
      submitted -> submitted
    end
  end

  defp submitted_or_entity_values(auix, key), do: entity_values(auix, key)

  @spec entity_values(map(), atom()) :: term()
  defp entity_values(auix, key),
    do: auix |> Map.get(:entity) |> Kernel.||(%{}) |> Map.get(key)

  # How the toggle-all checkbox renders. Compared as strings because `@selected` holds native option
  # values before the first change event and strings after it. An empty option list is `:none`,
  # never `:all` -- a toggle claiming "everything is selected" over nothing is a lie.
  @spec toggle_state(map()) :: :all | :none | :mixed
  defp toggle_state(%{select_opts: %{options: []}}), do: :none

  defp toggle_state(%{select_opts: %{options: options}, selected: selected}) do
    selected = MapSet.new(selected, &to_string/1)

    members =
      Enum.count(options, fn {_label, value} -> MapSet.member?(selected, to_string(value)) end)

    cond do
      members == 0 -> :none
      members == length(options) -> :all
      true -> :mixed
    end
  end

  # The display labels of the current selection, in option order. Compared as strings for the same
  # reason `toggle_state/1` is.
  @spec selected_labels(map()) :: list(binary())
  defp selected_labels(%{select_opts: %{options: options}, selected: selected}) do
    selected = MapSet.new(selected, &to_string/1)

    for {label, value} <- options, MapSet.member?(selected, to_string(value)), do: label
  end
end
