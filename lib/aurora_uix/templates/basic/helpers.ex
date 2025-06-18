defmodule Aurora.Uix.Web.Templates.Basic.Helpers do
  @moduledoc """
  Helper functions for LiveView components providing routing, assignment management, and entity-related utilities.
  Includes functions for managing navigation stacks, assigning values to LiveView sockets, and handling
  entity relationships.
  """

  use Phoenix.Component
  use Phoenix.LiveComponent

  import Aurora.Uix.Template, only: [safe_existing_atom: 1]
  import Aurora.Uix.Layout.Helper, only: [set_field_id: 1]

  alias Aurora.Uix.Field
  alias Aurora.Uix.Stack
  alias Phoenix.LiveView.JS

  @doc """
  Assigns a new entity to the socket based on related parameters.

  ## Parameters
  - socket (Phoenix.LiveView.Socket.t()) - The LiveView socket
  - params (map()) - Map containing optional related_key and parent_id for relationships
  - default (struct()) - Default entity struct for new records

  ## Returns
  - Phoenix.LiveView.Socket.t()
  """
  @spec assign_new_entity(Phoenix.Socket.t(), map(), struct()) :: Phoenix.Socket.t()
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
  - params (map()) - Parameters map

  ## Returns
  - Phoenix.LiveView.Socket.t()
  """
  @spec assign_index_row_click(Phoenix.LiveView.Socket.t(), map()) :: Phoenix.LiveView.Socket.t()
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

  ## Returns
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

  ## Returns
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

  ## Returns
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

  ## Returns
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

  ## Returns
  - Phoenix.LiveView.Socket.t()
  """
  @spec assign_auix_current_path(Phoenix.LiveView.Socket.t(), binary() | URI.t()) ::
          Phoenix.LiveView.Socket.t()
  def assign_auix_current_path(socket, url) do
    assign_auix(socket, :_current_path, url |> URI.parse() |> Map.get(:path))
  end

  @doc """
  Assigns routing stack to the socket. Decodes stack from params or uses default route.

  ## Parameters
  - socket (Phoenix.LiveView.Socket.t()) - The LiveView socket
  - params (map()) - Parameters containing encoded routing stack
  - default_route (map() | nil) - Optional default route if no stack exists

  ## Returns
  - Phoenix.LiveView.Socket.t()
  """
  @spec assign_auix_routing_stack(Phoenix.LiveView.Socket.t(), map(), map() | nil) ::
          Phoenix.LiveView.Socket.t()
  def assign_auix_routing_stack(socket, params, default_route \\ nil)

  def assign_auix_routing_stack(
        socket,
        %{"routing_stack" => encoded_routing_stack},
        _default_route
      ) do
    encoded_routing_stack
    |> decode_routing_stack()
    # |> Map.get("values", [])
    # |> Enum.map(&%{path: &1["path"], type: String.to_existing_atom(&1["type"])})
    # |> Stack.new()
    |> then(&assign_auix(socket, :_routing_stack, &1))
  end

  def assign_auix_routing_stack(socket, _params, nil) do
    assign_auix(socket, :_routing_stack, Stack.new())
  end

  def assign_auix_routing_stack(socket, _params, default_route) do
    default_route
    |> Stack.new()
    |> then(&assign_auix(socket, :_routing_stack, &1))
  end

  @doc """
  Handles forward navigation by updating the routing stack and navigating to the new path.

  ## Parameters
  - socket (Phoenix.LiveView.Socket.t()) - The LiveView socket
  - navigation (keyword()) - Navigation options with :navigate or :patch key

  ## Returns
  - Phoenix.LiveView.Socket.t()
  """
  @spec auix_route_forward(Phoenix.LiveView.Socket.t(), keyword()) :: Phoenix.LiveView.Socket.t()
  def auix_route_forward(
        %{assigns: %{_auix: %{_current_path: current_path}}} = socket,
        navigation
      ) do
    socket
    |> add_forward_path(current_path, navigation)
    |> route_to(navigation)
  end

  @doc """
  Handles backward navigation by popping the last route from the stack.

  ## Parameters
  - socket (Phoenix.LiveView.Socket.t()) - The LiveView socket

  ## Returns
  - Phoenix.LiveView.Socket.t()
  """
  @spec auix_route_back(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
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

  ## Returns
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

  ## Returns
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
    |> Map.get(field_name, Field.new(%{field: field_name, resource: resource_name}))
    |> Field.change(Map.get(field, :config, []))
    |> set_field_id()
  end

  @doc """
  Extracts association fields from preload configuration grouped by association type.

  ## Parameters
  - parsed_opts (map()) - Configuration map containing preload and resource settings

  ## Returns
  - map() - Map with association field types (:one_to_many, :many_to_one) as keys and lists of field names as values
  """
  @spec extract_association_preload(map()) :: map()
  def extract_association_preload(parsed_opts) do
    parsed_opts
    |> Map.get(:preload)
    |> List.flatten()
    |> Enum.map(&elem(&1, 0))
    |> Enum.uniq()
    |> Enum.map(&get_field(%{name: &1}, parsed_opts._configurations, parsed_opts._resource_name))
    |> Enum.filter(&(&1.field_type in [:many_to_one_association, :one_to_many_association]))
    |> Enum.map(&{&1.field_type, &1.field})
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
  end

  @doc """
  Flattens a nested structure of elements into a list of paths.

  ## Parameters
  - elements (map() | list()) - Nested structure containing inner_elements and tags
  - result (list()) - Accumulated result, defaults to empty list

  ## Returns
  - list() - Flattened list of maps containing tag and name information
  """
  @spec flat_paths(map() | list(), list()) :: list()
  def flat_paths(elements, result \\ [])
  def flat_paths([], result), do: result

  def flat_paths(%{inner_elements: inner_elements} = path, result) do
    flat_paths(inner_elements, [%{tag: path.tag, name: path[:name]} | result])
  end

  def flat_paths([%{inner_elements: inner_elements} | rest], result) do
    inner_elements
    |> Enum.reduce(result, &flat_paths(&1.inner_elements, [%{tag: &1.tag, name: &1[:name]} | &2]))
    |> then(&flat_paths(rest, &1))
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
    changeset
    |> Ecto.Changeset.traverse_errors(fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
    |> Enum.map_join("<br>", &"#{elem(&1, 0)}: #{elem(&1, 1)}")
  end

  ## PRIVATE
  # Performs JavaScript navigation to a given URI, ensuring proper decode and formatting
  @spec js_navigate(binary()) :: JS.t()
  defp js_navigate(uri) do
    "/#{uri}"
    |> URI.decode()
    |> JS.navigate()
  end

  # Adds a path to the forward navigation stack and updates last route path in assigns
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

  # Handles route changes based on navigation type and current routing stack
  @spec route_to(Phoenix.LiveView.Socket.t(), map() | keyword()) :: Phoenix.LiveView.Socket.t()
  defp route_to(%{assigns: %{_auix: %{_routing_stack: stack}}} = socket, %{
         type: :navigate,
         path: path
       }) do
    push_navigate(socket, to: route_path_with_stack(path, stack))
  end

  defp route_to(%{assigns: %{_auix: %{_routing_stack: stack}}} = socket, %{
         type: :patch,
         path: path
       }) do
    push_patch(socket, to: route_path_with_stack(path, stack))
  end

  defp route_to(socket, to: path), do: route_to(socket, %{type: :navigate, path: path})

  defp route_to(socket, patch: path), do: route_to(socket, %{type: :patch, path: path})

  # Converts navigation keyword options to route type atoms
  @spec route_type(keyword()) :: atom()
  defp route_type(to: _path), do: :navigate
  defp route_type(patch: _path), do: :patch

  # Builds a complete path with routing stack encoded as a query parameter
  @spec route_path_with_stack(binary(), map()) :: binary()
  defp route_path_with_stack(path, routing_stack) do
    query_parameter_separator = if String.contains?(path, "?"), do: "&", else: "?"

    routing_stack
    |> encode_routing_stack()
    |> then(&"#{path}#{query_parameter_separator}routing_stack=#{&1}")
  end

  # Encodes routing stack into a compressed, Base64 URL-safe string
  @spec encode_routing_stack(struct()) :: binary()
  defp encode_routing_stack(routing_stack) do
    routing_stack
    |> Map.from_struct()
    |> Jason.encode!()
    # |> :zlib.compress()
    # |> Base.encode64()
    |> URI.encode_www_form()
  end

  # Decodes an obfuscated routing stack string back into a stack struct
  @spec decode_routing_stack(binary()) :: struct()
  defp decode_routing_stack(obfuscated) do
    obfuscated
    # |> Base.decode64!()
    # |> :zlib.uncompress()s
    |> Jason.decode!()
    |> Map.get("values", [])
    |> Enum.map(&%{path: &1["path"], type: String.to_existing_atom(&1["type"])})
    |> Stack.new()
  end
end
