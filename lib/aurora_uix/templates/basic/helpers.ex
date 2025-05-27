defmodule Aurora.Uix.Web.Templates.Basic.Helpers do
  @moduledoc """
  Helper functions for LiveView components.
  """

  use Phoenix.Component
  use Phoenix.LiveComponent

  import Aurora.Uix.Template, only: [safe_existing_atom: 1]

  alias Phoenix.LiveView.JS

  @doc """
  Assigns a new entity to the socket based on related parameters.

  ## Parameters
    - socket (Phoenix.LiveView.Socket.t()) - The LiveView socket
    - params (map()) - Contains optional related_key and parent_id for relationships
    - default (struct()) - Default entity struct for new records

  Returns:
    - Phoenix.LiveView.Socket.t()
  """
  @spec assign_new_entity(Phoenix.Socket.t(), map, map) :: Phoenix.Socket.t()
  def assign_new_entity(
        socket,
        %{
          "related_key" => related_key,
          "parent_id" => parent_id
        },
        default
      ) do
    related_key
    |> safe_existing_atom()
    |> __maybe_set_related_to_new_entity__(socket, parent_id, default)
  end

  def assign_new_entity(socket, _params, default) do
    assign(socket, :auix_entity, default)
  end

  @doc """
  Assigns click handler for index rows based on parsed options.

  ## Parameters
    - socket (Phoenix.LiveView.Socket.t()) - The LiveView socket
    - _params (map()) - Unused parameters map

  Returns:
    - Phoenix.LiveView.Socket.t()
  """
  @spec assign_index_row_click(Phoenix.LiveView.Socket.t(), map) ::
          Phoenix.LiveView.Socket.t()
  def assign_index_row_click(%{assigns: assigns} = socket, _params) do
    parsed_opts = Map.get(assigns, :_auix, %{})

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
  Assigns parsed options to the _auix assigns map in the socket.

  ## Parameters
    - socket (Phoenix.LiveView.Socket.t()) - The LiveView socket
    - parsed_opts (map()) - Options to merge with existing _auix assigns

  Returns:
    - Phoenix.LiveView.Socket.t()
  """
  @spec assign_parsed_opts(Phoenix.LiveView.Socket.t(), map()) :: Phoenix.LiveView.Socket.t()
  def assign_parsed_opts(socket, parsed_opts) do
    socket.assigns
    |> Map.get(:_auix, %{})
    |> then(&Map.merge(parsed_opts, &1))
    |> then(&assign(socket, :_auix, &1))
  end

  @doc """
  Assigns a value to the _auix assigns map in the socket.

  ## Parameters
    - socket (Phoenix.LiveView.Socket.t()) - The LiveView socket
    - key (atom()) - Key for storing in _auix map
    - value (term()) - Value to store

  Returns:
    - Phoenix.LiveView.Socket.t()
  """
  @spec assign_auix(Phoenix.LiveView.Socket.t(), atom, any) :: Phoenix.LiveView.Socket.t()
  def assign_auix(socket, key, value) do
    socket.assigns
    |> Map.get(:_auix, %{})
    |> Map.put(key, value)
    |> then(&assign(socket, :_auix, &1))
  end

  @doc """
  Assigns a value to the _auix assigns map in the socket only if it does not exist.

  ## Parameters
    - socket (Phoenix.LiveView.Socket.t()) - The LiveView socket
    - key (atom()) - Key for storing in _auix map
    - value (term()) - Value to store

  Returns:
    - Phoenix.LiveView.Socket.t()
  """
  @spec assign_auix_new(Phoenix.LiveView.Socket.t(), atom, any) :: Phoenix.LiveView.Socket.t()
  def assign_auix_new(socket, key, value) do
    socket.assigns
    |> Map.get(:_auix, %{})
    |> Map.put_new(key, value)
    |> then(&assign(socket, :_auix, &1))
  end

  @doc """
  Assigns section configuration to _auix assigns map.

  ## Parameters
    - socket (Phoenix.LiveView.Socket.t()) - The LiveView socket
    - sections_id (binary()) - Identifier for the sections group
    - tab_id (binary()) - Identifier for the active tab

  Returns:
    - Phoenix.LiveView.Socket.t()
  """
  @spec assign_auix_sections(Phoenix.LiveView.Socket.t(), binary(), binary()) ::
          Phoenix.LiveView.Socket.t()
  def assign_auix_sections(%{assigns: assigns} = socket, sections_id, tab_id) do
    assigns._auix
    |> Map.get(:_sections)
    |> Map.put(sections_id, tab_id)
    |> then(&assign_auix(socket, :_sections, &1))
  end

  @doc """
  Extracts and assigns the current path out of the current url, to the _auix map.

  ## Parameters
    - socket (Phoenix.LiveView.Socket.t()) - The LiveView socket
    - url (binary()) - Actual url.

  Returns:
    - Phoenix.LiveView.Socket.t()
  """
  @spec assign_auix_current_path(Phoenix.LiveView.Socket.t(), binary() | URI.t()) ::
          Phoenix.LiveView.Socket.t()
  def assign_auix_current_path(socket, url) do
    assign_auix(socket, :_current_path, url |> URI.parse() |> Map.get(:path))
  end

  @doc """
  Assigns the path to navigate back.

  ## Parameters
    - socket (Phoenix.LiveView.Socket.t()) - The LiveView socket
    - params (map()) - Contains optiona back_path value

  Returns:
    - Phoenix.LiveView.Socket.t()
  """
  @spec assign_auix_back_path(Phoenix.LiveView.Socket.t(), map) ::
          Phoenix.LiveView.Socket.t()
  def assign_auix_back_path(socket, %{"back_path" => back_path}),
    do: assign_auix(socket, :_back_path, back_path)

  def assign_auix_back_path(socket, _params),
    do: assign_auix(socket, :_back_path, Map.get(socket.assigns._auix, :_current_path, ""))

  @doc """
  Generates a link for showing an entity in the index view.

  ## Parameters
    - auix (map()) - Configuration map with index_show_entity_link setting
    - entity (map()) - Entity data with id field

  Returns:
    - binary()
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
    - source (binary()) - The source identifier
    - auix_entity (map()) - Entity with id and owner key value
    - related_key (atom()) - Key identifying the relation
    - owner_key (atom()) - Key identifying the owner field

  Returns:
    - binary()
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

  ## PRIVATE
  @spec navigate(binary) :: JS.t()
  defp navigate(uri) do
    "/#{uri}"
    |> URI.decode()
    |> JS.navigate()
  end
end
