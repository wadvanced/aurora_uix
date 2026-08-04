defmodule Aurora.Uix.Templates.Basic.Renderers.OneToOne do
  @moduledoc """
  Renders one-to-one (`has_one`) association fields as an inline nested form or group.

  A `has_one` matches neither of the other association renderers: the foreign key lives on the
  *remote* side (like `has_many`) while the cardinality is *1* (like `belongs_to`). There is no
  local column for a `<select>` to bind to, and a sub-index table with an "add another" action
  would contradict the cardinality. The shape used here is therefore the one
  `Aurora.Uix.Templates.Basic.Renderers.EmbedsOneRenderer` builds: nested inputs that submit in the
  same POST as the parent.

  ## Key Features

  - `:form` renders the child's `:form` layout inline through `<.inputs_for>`, so the child is
    created or updated in the same request as the parent.
  - Nested inputs are always present, even when no child record exists yet.
  - `:show` renders the child's `:show` layout as a read-only group, or an empty-field message when
    there is no child.
  - The child's foreign key back-reference is suppressed, so the parent is not offered as a
    redundant selector inside its own nested form.
  - Renders nothing when the related schema is not a registered Aurora UIX resource.

  ## Key Constraints

  - The library is **transport-only** for writes: it renders nested input names and forwards params
    untouched, and never builds a changeset. Persisting the child is the host's responsibility —
    `cast_assoc/3` in an Ecto changeset, or `argument` + `change manage_relationship(...)` in an Ash
    action.
  - An Ash host whose action declares no matching `argument` + `manage_relationship` raises
    `AshPhoenix.Form.NoFormConfigured`. This is deliberate — swallowing it would make the
    misconfiguration invisible until data silently failed to persist.
  - A submission where every nested input is blank is forwarded unchanged. Whether that means
    "skip the child" or "invalid" is decided by the host's changeset or action, not here.
  - Requires the related resource to be registered and its `:form` / `:show` layout resolvable;
    otherwise no nested elements render.
  - The parent must be preloaded for `:show` and for editing a persisted record. `filter_preloads/1`
    handles this; a missing preload surfaces as an unloaded association, not as rendered inputs.
  """

  use Aurora.Uix.CoreComponentsImporter
  use Aurora.Uix.GettextResolver

  alias Aurora.Uix.Templates.Basic.Helpers, as: BasicHelpers
  alias Aurora.Uix.Templates.Basic.Renderer

  @doc """
  Renders a one-to-one association field.

  ## Parameters
  - `assigns` (map()) - LiveView assigns containing:
    * `:field` (map()) - Field configuration with association details in `:data`.
    * `:auix` (map()) - Aurora UIX context with form, entity and layout configuration.

  ## Returns
  Phoenix.LiveView.Rendered.t() - Rendered one-to-one association component.
  """
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(%{field: %{type: :one_to_one_association, data: %{resource: nil}}} = assigns) do
    ~H"""
    """
  end

  def render(
        %{field: %{type: :one_to_one_association} = field, auix: %{layout_type: :form}} = assigns
      ) do
    assigns = assign_related_layout(assigns, field, :form)

    ~H"""
    <div id={"auix-one-to-one-#{@field.key}-#{@auix.layout_type}"} class="auix-one-to-one-container">
      <.header>
        {dt(@field.label)}
      </.header>
      <.inputs_for :let={child_form} field={@auix.form[@field.key]}>
        <Renderer.render_inner_elements auix={
          Map.merge(@auix, %{form: child_form, fields_to_reject: [@field.data.related_key]})
        } />
      </.inputs_for>
    </div>
    """
  end

  def render(
        %{field: %{type: :one_to_one_association} = field, auix: %{layout_type: :show}} = assigns
      ) do
    child = related_entity(assigns.auix.entity, field)

    assigns =
      assigns
      |> assign_related_layout(field, :show)
      |> BasicHelpers.assign_auix(:entity, child)
      |> assign(:is_empty?, is_nil(child))

    ~H"""
    <div id={"auix-one-to-one-#{@field.key}-#{@auix.layout_type}"} class="auix-one-to-one-container">
      <.header>
        {dt(@field.label)}
        <:subtitle :if={@is_empty?}>
          <span class="auix-one-to-one-empty-msg">
            {dt("Field is empty")}
          </span>
        </:subtitle>
      </.header>
      <Renderer.render_inner_elements :if={!@is_empty?} auix={@auix} />
    </div>
    """
  end

  ## PRIVATE ##

  # Points the auix context at the related resource, so the nested elements resolve against the
  # child's layout instead of the parent's.
  @spec assign_related_layout(map(), map(), atom()) :: map()
  defp assign_related_layout(
         assigns,
         %{data: %{resource: related_resource_name}} = field,
         layout_type
       ) do
    layout_tree = BasicHelpers.get_layout(assigns, related_resource_name, layout_type)

    assigns
    |> BasicHelpers.assign_auix(:layout_tree, layout_tree)
    |> BasicHelpers.assign_auix(:resource_name, related_resource_name)
    |> assign(:field, field)
  end

  # Reads the child record off the parent, treating "absent" and "not loaded" alike. Matching on the
  # related schema rather than on a backend's not-loaded struct keeps this backend-agnostic.
  @spec related_entity(map() | nil, map()) :: struct() | nil
  defp related_entity(entity, %{key: key, data: %{related: related}}) do
    entity
    |> Kernel.||(%{})
    |> Map.get(key)
    |> then(&if(is_struct(&1, related), do: &1))
  end
end
