defmodule Aurora.Uix.Web.Templates.Core.Helpers do
  @moduledoc """
  Helper functions for LiveView components.
  """

  use Phoenix.Component
  use Phoenix.LiveComponent

  import Aurora.Uix.Web.Template, only: [safe_existing_atom: 1]

  alias Phoenix.LiveView.JS

  @doc """
  Assigns a new entity to the socket based on related parameters.

  ## Parameters
    * `socket` - The LiveView socket.
    * `params` - A map containing optional "related_key" and "parent_id" keys for relationship setup.
    * `default` - The default entity struct to use when creating a new entity.
  """
  def assign_new_entity(
        socket,
        %{"related_key" => related_key, "parent_id" => parent_id},
        default
      ) do
    related_key
    |> safe_existing_atom()
    |> __maybe_set_related_to_new_entity__(socket, parent_id, default)
  end

  @spec assign_new_entity(Phoenix.Socket.t(), map, map) :: Phoenix.Socket.t()
  def assign_new_entity(socket, _params, default) do
    assign(socket, :auix_entity, default)
  end

  @doc """
  Assigns source-related data to the socket based on provided parameters.

  ## Parameters
    * `socket` - The LiveView socket.
    * `params` - A map that may contain a "source" key.
    * `default_source` - The default source value to use when no source is provided.
  """
  @spec assign_source(Phoenix.LiveView.Socket.t(), map, binary) ::
          Phoenix.LiveView.Socket.t()
  def assign_source(socket, params, default_source) do
    params
    |> Map.get("source")
    |> __maybe_set_different_source_and_link__(socket, default_source)
  end

  @doc """
  Assigns click handler for index rows based on parsed options.

  ## Parameters
    * `socket` - The LiveView socket.
    * `_params` - Unused parameters map.
    * `parsed_opts` - Options map containing :disable_index_row_click and :index_row_click settings.
  """
  @spec assign_index_row_click(Phoenix.LiveView.Socket.t(), map, map) ::
          Phoenix.LiveView.Socket.t()
  def assign_index_row_click(socket, _params, parsed_opts) do
    index_row_click =
      if parsed_opts[:disable_index_row_click],
        do: nil,
        else: fn {_id, row} ->
          id = Map.get(row, :id)

          parsed_opts
          |> Map.get(:index_row_click, "#")
          |> String.replace("[[entity]]", to_string(id))
          |> then(&navigate/1)
        end

    assign_auix(socket, :index_row_click, index_row_click)
  end

  @doc """
  Assigns a value to the _auix assigns map in the socket.

  ## Parameters
    * `socket` - The LiveView socket.
    * `key` - The key under which to store the value in _auix.
    * `value` - The value to store.
  """
  @spec assign_auix(Phoenix.LiveView.Socket.t(), atom, any) :: Phoenix.LiveView.Socket.t()
  def assign_auix(socket, key, value) do
    socket.assigns
    |> Map.get(:_auix, %{})
    |> Map.put(key, value)
    |> then(&assign(socket, :_auix, &1))
  end

  @doc """
  Generates a link for showing an entity in the index view.

  ## Parameters
    * `auix` - The auix configuration map containing :index_show_entity_link.
    * `entity` - The entity map containing the :id field.
  """
  @spec index_show_entity_link(map, map) :: binary
  def index_show_entity_link(auix, entity) do
    auix
    |> Map.get(:index_show_entity_link, "#")
    |> String.replace("[[entity]]", entity |> Map.get(:id) |> to_string())
    |> then(fn link -> URI.decode("/#{link}") end)
  end

  @doc """
  Generates a path string for related entities.

  ## Parameters
    * `source` - The source identifier.
    * `auix_entity` - The entity map containing :id and owner key value.
    * `related_key` - The key identifying the relation.
    * `owner_key` - The key identifying the owner field.
  """
  @spec related_path(binary, map, atom, atom) :: binary
  def related_path(_source, _auix_entity, nil, _owner_key), do: ""
  def related_path(_source, _auix_entity, _related_key, nil), do: ""
  def related_path(_source, %{id: nil}, _related_key, _owner_key), do: ""

  def related_path(source, %{id: id} = auix_entity, related_key, owner_key) do
    "source=#{source}/#{id}&related_key=#{related_key}&parent_id=#{Map.get(auix_entity, owner_key)}"
  end

  def related_path(_parsed_opts, _auix_entity, _related_key, _owner_key), do: ""

  ## Non imported
  @doc false
  @spec __maybe_set_related_to_new_entity__(
          binary | nil,
          Phoenix.LiveView.Socket.t(),
          binary | nil,
          struct
        ) :: Phoenix.LiveView.Socket.t()
  def __maybe_set_related_to_new_entity__(related_key, socket, parent_id, default)
      when is_nil(related_key) or is_nil(parent_id),
      do: assign(socket, :auix_entity, default)

  def __maybe_set_related_to_new_entity__(related_key, socket, parent_id, default) do
    default
    |> struct(%{related_key => parent_id})
    |> then(&assign(socket, :auix_entity, &1))
  end

  @doc false
  @spec __maybe_set_different_source_and_link__(
          binary | nil,
          Phoenix.LiveView.Socket.t(),
          binary | nil
        ) :: Phoenix.LiveView.Socket.t()
  def __maybe_set_different_source_and_link__(nil, socket, default_source) do
    socket
    |> assign(:_auix_source, default_source)
    |> assign(:_auix_source_link, "")
  end

  def __maybe_set_different_source_and_link__(source, socket, _default_source) do
    socket
    |> assign(:_auix_source, source)
    |> assign(:_auix_source_link, "?source=#{source}")
  end

  ## PRIVATE
  @spec navigate(binary) :: JS.t()
  defp navigate(uri) do
    "/#{uri}"
    |> URI.decode()
    |> JS.navigate()
  end
end
