defmodule Aurora.Uix.Web.Templates.Basic.Helpers do
  @moduledoc """
  Helper functions for LiveView components.
  """

  use Phoenix.Component
  use Phoenix.LiveComponent

  import Aurora.Uix.Template, only: [safe_existing_atom: 1]

  alias Aurora.Uix.Stack
  alias Aurora.Uix.Field
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
          |> then(&js_navigate/1)
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

  @spec assign_auix_routing_stack(Phoenix.LiveView.Socket.t(), map(), map() | nil) :: Phoenix.LiveView.Socket.t()
  def assign_auix_routing_stack(socket, params, default_route \\ nil)
  def assign_auix_routing_stack(socket, %{"routing_stack" => encoded_routing_stack}, _default_route) do
    encoded_routing_stack
    |> Jason.decode!()
    |> Map.get("values")
    |> Enum.map(&%{path: &1["path"], type: String.to_existing_atom(&1["type"])})
    |> Stack.new()
    |> then(&assign_auix(socket, :_routing_stack, &1))
  end

  def assign_auix_routing_stack(socket, _params, %{} = default_route) do
    default_route
    |> Stack.new()
    |> then(&assign_auix(socket, :_routing_stack, &1))
  end

  def assign_auix_routing_stack(socket, _params, _default_route), do: socket

  @spec auix_route_forward(Phoenix.LiveView.Socket.t(), keyword()) :: Phoenix.LiveView.Socket.t()
  def auix_route_forward(
        %{assigns: %{_auix: %{_current_path: current_path}}} = socket,
        navigation
      ) do
    socket
    |> add_forward_path(current_path, navigation)
    |> route_to(navigation)
  end

  def auix_route_back(%{assigns: %{_auix: %{_routing_stack: routing_stack}}} = socket) do
    {new_navigation_stack, back_path} = Stack.pop!(routing_stack)

    socket
    |> assign_auix(:_routing_stack, new_navigation_stack)
    |> route_to(Map.new(back_path))
  end

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

  @doc """
  Retrieves and processes field configuration from the resource configurations.

  Parameters:
  - field: %{name: atom()} - Map containing the field name and options
  - configurations: map - Global configurations for all resources
  - resource_name: atom - The name of the resource the field belongs to

  Returns:
  - Field.t() - A Field struct containing the processed field configuration
  """
  @spec get_field(map, map, atom) :: Field.t()
  def get_field(%{name: field_name} = field, configurations, resource_name) do
    configurations
    |> Map.get(resource_name, %{})
    |> Map.get(:resource_config, %{})
    |> Map.get(:fields, %{})
    |> Map.get(field_name, Field.new(%{field: field_name}))
    |> Field.change(Map.get(field, :opts, []))
  end

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

  @doc """
  A helper that transforms changeset errors into a map of messages.

      assert {:error, changeset} = Accounts.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  """
  @spec format_changeset_errors(Ecto.Changeset.t()) :: binary
  def format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
    |> Enum.map(&"#{elem(&1, 0)}: #{elem(&1, 1)}")
    |> Enum.join("<br>")
  end

  ## PRIVATE
  @spec js_navigate(binary) :: JS.t()
  defp js_navigate(uri) do
    "/#{uri}"
    |> URI.decode()
    |> JS.navigate()
  end

  @spec add_forward_path(Phoenix.LiveView.Socket.t(), binary(), keyword()) ::
          Phoenix.LiveView.Socket.t()
  defp add_forward_path(%{assigns: %{_auix: %{_routing_stack: stack}}} = socket, path, navigation) do
    navigation_entry =
      navigation
      |> route_type()
      |> then(&%{type: &1, path: path})

    stack
    |> Stack.push(navigation_entry)
    |> then(&assign_auix(socket, :_routing_stack, &1))
    |> assign_auix(:_last_route_path, path)
  end

  defp add_forward_path(socket, _path, _navigation), do: socket

  @spec route_to(Phoenix.LiveView.Socket.t(), map() | keyword()) :: Phoenix.LiveView.Socket.t()
  defp route_to(%{assigns: %{_auix: %{_routing_stack: stack}}} = socket, %{type: :to, path: path}),
    do: push_navigate(socket, to: route_path_with_stack(path, stack))

  defp route_to(%{assigns: %{_auix: %{_routing_stack: stack}}} = socket, %{
         type: :patch,
         path: path
       }),
       do: push_patch(socket, to: route_path_with_stack(path, stack))

  defp route_to(socket, to: path), do: route_to(socket, %{type: :to, path: path})

  defp route_to(socket, patch: path), do: route_to(socket, %{type: :patch, path: path})

  defp route_type(to: _path), do: :to
  defp route_type(patch: _path), do: :patch

  defp route_path_with_stack(path, routing_stack) do
    routing_stack
    |> Map.from_struct()
    |> Jason.encode!()
    |> then(&"#{path}?routing_stack=#{&1}")
  end
end
