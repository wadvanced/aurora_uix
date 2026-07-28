defmodule Aurora.Uix.Templates.Basic.Renderers.ManyToMany do
  @moduledoc """
  Renders many-to-many association fields as a list of checkboxes over the related records.

  Membership is a *set of existing records*, not a child the parent owns, so neither of the other
  association renderers fits: there is no local foreign key for `ManyToOne`'s single select to bind
  to, and `OneToMany`'s "create a new child" flow is the wrong verb — the user picks from records
  that already exist. A checkbox list expresses exactly the available operations: the checked set
  *is* the membership, so adding and removing are the same gesture.

  Checkboxes rather than a `<select multiple>`: multi-select needs a modifier-key gesture that is
  undiscoverable and unusable on touch, conveys state only through a background colour, and has
  nowhere to host bulk controls. The wire format is identical — every box shares the
  `parent[field][]` name, so only checked values are submitted, exactly as only selected options
  are — which is why the sentinel below and the host's persistence contract are unchanged.

  Reads come from the preloaded association (`filter_preloads/1` puts the field in
  `parsed_opts.preload`), and the candidate list comes from the related resource's own
  `list_function`. No join-aware query is involved: both backends resolve the join table during
  preload.

  ## Key Features

  - `:form` renders one checkbox per candidate record; the checked boxes are the current membership.
  - Submits in the same POST as the parent, under `parent[field][]`.
  - Emits a hidden empty-value sentinel so that de-selecting everything still submits the key, which
    is what makes clearing the last membership possible at all.
  - Ships `:default_check_all` / `:default_uncheck_all` header actions, registered through
    `Aurora.Uix.Action`'s `:many_to_many` group, plus an empty footer group — so a host adds,
    replaces or removes any of them from the layout DSL field options.
  - Honours the `option_label:` field option through the shared
    `Aurora.Uix.Templates.Basic.Helpers.get_select_options/1`; when the host declares none, the
    label falls back to a conventional display column (`:name`, `:title`, …) of the related
    resource's `:index` layout, instead of the record's raw primary key.
  - `:show` renders the same checkbox list disabled.
  - Renders nothing when the related schema is not a registered Aurora UIX resource.

  ## Key Constraints

  - The library is **transport-only** for writes: it renders the input name and forwards the
    submitted list of primary keys untouched, and never builds a changeset. Persisting membership is
    the host's responsibility — `put_assoc/4` in an Ecto changeset, or `argument` +
    `change manage_relationship(..., type: :append_and_remove)` in an Ash action.
  - Because of the sentinel, the submitted list **always** carries one blank entry. The host must
    reject it. On Ash the argument also needs `constraints: [nil_items?: true]`, since Ash casts a
    blank to `nil` and otherwise rejects the list with "no nil values" before any `change` runs.
  - An Ecto host must declare `on_replace: :delete` on the association, or `put_assoc/4` raises.
    That option is also what deletes the join rows — removing a member must never delete the related
    record itself.
  - `html_type` stays `:select`: the field *is* a set of options, only the widget changed, and
    `get_select_options/1` dispatches on it.
  - Checking or clearing everything is a server round trip
    (`"auix_many_to_many_toggle_all"`, handled by `Aurora.Uix.Templates.Basic.Handlers.FormImpl`),
    which costs one extra `list_function` call per click. It cannot be done client-side: the result
    has to reach `auix.form.params` or the next `phx-change` would discard it.
  - Requires the related resource to be registered, and the parent to be preloaded for `:show` and
    for editing a persisted record.
  """

  use Aurora.Uix.CoreComponentsImporter
  use Aurora.Uix.Gettext

  import Aurora.Uix.Templates.Basic.Components

  alias Aurora.Uix.Templates.Basic.Actions.ManyToMany, as: ManyToManyActions
  alias Aurora.Uix.Templates.Basic.Helpers, as: BasicHelpers

  # An association or embed renders as a nested UI, never as a one-line option label.
  @non_label_types [
    :many_to_one_association,
    :one_to_many_association,
    :one_to_one_association,
    :many_to_many_association,
    :embeds_one,
    :embeds_many
  ]

  # Column order is not comparable across backends -- Ctx keeps the schema's declaration order,
  # Ash does not -- so the default label is chosen by name precedence rather than by position,
  # and only falls back to position when a resource names none of these.
  @preferred_label_names [:name, :title, :label, :reference, :code, :description, :slug]

  @doc """
  Renders a many-to-many association field.

  ## Parameters
  - `assigns` (map()) - LiveView assigns containing:
    * `:field` (map()) - Field definition with association details in `:data`.
    * `:auix` (map()) - Aurora UIX context with form, entity and layout configuration.

  ## Returns
  Phoenix.LiveView.Rendered.t() - Rendered many-to-many association component.
  """
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(%{field: %{type: :many_to_many_association, data: %{resource: nil}}} = assigns) do
    ~H"""
    """
  end

  def render(
        %{
          field: %{type: :many_to_many_association} = field,
          auix: %{layout_type: :form, layout_tree: layout_tree} = auix
        } = assigns
      ) do
    assigns =
      assigns
      |> assign_select(field)
      |> assign(:input_name, "#{auix.form[field.key].name}[]")
      |> put_in([:auix, :layout_tree, :opts], Map.get(layout_tree, :opts, []))
      |> ManyToManyActions.set_actions()

    ~H"""
    <div id={container_id(@field, @auix)} class="auix-many-to-many-container">
      <input type="hidden" name={@input_name} value="" />
      <.auix_checkbox_group
        id={options_id(@field, @auix)}
        name={@input_name}
        label={@select_label}
        options={@select_opts[:options]}
        value={@selected}
        empty_message={dt("No records available")}
      >
        <:actions>
          <%= for %{function_component: action} <- @auix.many_to_many_header_actions do %>
            {action.(%{auix: @auix, field: @field})}
          <% end %>
        </:actions>
      </.auix_checkbox_group>
      <div class="auix-many-to-many-footer-actions" name={"auix-many-to-many-footer-actions-#{@field.key}"}>
        <%= for %{function_component: action} <- @auix.many_to_many_footer_actions do %>
          {action.(%{auix: @auix, field: @field})}
        <% end %>
      </div>
    </div>
    """
  end

  def render(%{field: %{type: :many_to_many_association} = field} = assigns) do
    assigns = assign_select(assigns, field)

    ~H"""
    <div id={container_id(@field, @auix)} class="auix-many-to-many-container">
      <.auix_checkbox_group
        id={options_id(@field, @auix)}
        name={@field.key}
        label={@select_label}
        options={@select_opts[:options]}
        value={@selected}
        disabled={true}
        empty_message={dt("No records available")}
      />
    </div>
    """
  end

  ## PRIVATE ##

  # Computes the option list, the selected primary keys and the label, shared by both layout types.
  # The option list is resolved by `get_select_options/1` rather than built here, so the resolved
  # `option_label` is injected into the field *before* the call.
  @spec assign_select(map(), map()) :: map()
  defp assign_select(assigns, field) do
    assigns
    |> assign(:field, with_option_label(field, assigns.auix))
    |> then(&assign(&1, :select_opts, BasicHelpers.get_select_options(&1)))
    |> assign(:selected, selected_ids(assigns))
    |> assign(:select_label, select_label(assigns, field))
  end

  # Without an `option_label:`, `get_select_options/1` labels every option with the record's own
  # primary key, so the select renders a list of ids. The related resource already declares how it
  # presents a record -- its `:index` layout -- so resolve a label from there and let the shared
  # helper build the options exactly as it does for a host-declared `option_label:`.
  @spec with_option_label(map(), map()) :: map()
  defp with_option_label(%{data: %{option_label: _option_label}} = field, _auix), do: field

  defp with_option_label(%{data: data} = field, %{configurations: configurations}) do
    case default_option_label(configurations, data) do
      nil -> field
      option_label -> %{field | data: Map.put(data, :option_label, option_label)}
    end
  end

  # Best `:index` column of the related resource to stand in for the record.
  @spec default_option_label(map(), map()) :: atom() | nil
  defp default_option_label(configurations, %{resource: resource}) do
    candidates = label_candidates(configurations, resource)

    Enum.find(@preferred_label_names, &(&1 in candidates)) || List.first(candidates)
  end

  # The `:index` columns that can stand in for the record: not part of the primary key, and not
  # themselves an association or embed.
  @spec label_candidates(map(), atom()) :: list(atom())
  defp label_candidates(configurations, resource) do
    primary_key =
      configurations |> get_in([resource, :parsed_opts, :primary_key]) |> Kernel.||([])

    configurations
    |> get_in([resource, :layout_trees, :index, :inner_elements])
    |> Kernel.||([])
    |> Enum.flat_map(&column_name/1)
    |> Enum.reject(&(&1 in primary_key))
    |> Enum.filter(&label_candidate?(configurations, resource, &1))
  end

  # Nested layout tags carry a tuple name (or none); only plain columns can label an option.
  @spec column_name(map()) :: list(atom())
  defp column_name(%{tag: :field, name: name}) when is_atom(name), do: [name]
  defp column_name(_layout_tree), do: []

  @spec label_candidate?(map(), atom(), atom()) :: boolean()
  defp label_candidate?(configurations, resource, name) do
    %{name: name}
    |> BasicHelpers.get_field(configurations, resource)
    |> then(&(&1.type not in @non_label_types))
  end

  # Stable id: html_ids embed a global counter and are not stable across test ordering.
  @spec container_id(map(), map()) :: binary()
  defp container_id(%{key: key}, %{layout_type: layout_type}),
    do: "auix-many-to-many-#{key}-#{layout_type}"

  # Each checkbox derives its own id from this one. A stable per-input id is what lets LiveView
  # track and patch `checked`; without it, a second toggle-all click appears to do nothing.
  @spec options_id(map(), map()) :: binary()
  defp options_id(field, auix), do: "#{container_id(field, auix)}-options"

  # Association fields carry no label of their own unless the host sets one; fall back to the
  # related resource's name rather than rendering an unlabelled select.
  @spec select_label(map(), map()) :: binary()
  defp select_label(%{auix: %{configurations: configurations}}, %{label: label, data: data}) do
    if label in [nil, ""] do
      configurations
      |> get_in([data.resource, :parsed_opts, :name])
      |> Kernel.||("")
      |> dt()
    else
      dt(label)
    end
  end

  # The primary keys that must render as selected.
  @spec selected_ids(map()) :: list()
  defp selected_ids(%{
         field: %{key: key, data: %{related: related, related_key: related_key}},
         auix: auix
       }) do
    auix
    |> membership(key)
    |> to_ids(related, related_key)
  end

  # Submitted params win when present, so an in-flight edit survives re-render. `form[key].value` is
  # deliberately not used: for Ecto it may hold changesets after `put_assoc`, and for Ash the field
  # is an action argument that is still nil on the first `:edit` render.
  @spec membership(map(), atom()) :: term()
  defp membership(%{form: %{params: params}} = auix, key) do
    case Map.get(params, to_string(key)) do
      nil -> entity_membership(auix, key)
      submitted -> submitted
    end
  end

  defp membership(auix, key), do: entity_membership(auix, key)

  @spec entity_membership(map(), atom()) :: term()
  defp entity_membership(auix, key),
    do: auix |> Map.get(:entity) |> Kernel.||(%{}) |> Map.get(key)

  # Anything that is not a list -- nil, or a backend's not-loaded struct -- means "nothing selected".
  @spec to_ids(term(), module(), atom()) :: list()
  defp to_ids(values, related, related_key) when is_list(values) do
    values
    |> Enum.map(&entry_id(&1, related, related_key))
    |> Enum.reject(&(is_nil(&1) or &1 == ""))
  end

  defp to_ids(_values, _related, _related_key), do: []

  # Matching the related schema rather than a backend's not-loaded struct keeps this
  # backend-agnostic: `Ecto.Association.*` may only appear under `integration/ctx/`.
  @spec entry_id(term(), module(), atom()) :: term() | nil
  defp entry_id(entry, related, related_key) when is_struct(entry, related),
    do: Map.get(entry, related_key)

  defp entry_id(entry, _related, _related_key) when is_binary(entry) or is_integer(entry),
    do: entry

  defp entry_id(_entry, _related, _related_key), do: nil
end
