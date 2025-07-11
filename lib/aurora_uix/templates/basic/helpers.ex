defmodule Aurora.Uix.Web.Templates.Basic.Helpers do
  @moduledoc """
  Provides utility functions for LiveView components in Aurora UIX.

  ## Key Features
  - Manages navigation stacks for LiveView routing.
  - Assigns values and parsed options to LiveView sockets.
  - Handles entity relationships and section/tab assignment.

  ## Navigation Helpers
  These functions help with routing and navigation stack management.

  ## Assign Helpers
  These functions help with assigning values to the socket or assigns map.

  ## Entity Helpers
  These functions assist with entity creation and relationship handling.

  ## Error Helpers
  These functions are used for error formatting and processing.

  ## Field Helpers
  These functions are for retrieving and processing field configurations.

  ## Layout Helpers
  These functions handle layout options assignment and retrieval.

  ## Action Helpers
  These functions manage actions within the assigns map, such as adding or removing actions.

  ## Path Helpers
  These functions deal with path and URL manipulations.
  """

  use Phoenix.Component
  use Phoenix.LiveComponent

  alias Aurora.Uix.Action
  alias Aurora.Uix.Field
  alias Aurora.Uix.Layout.Options, as: LayoutOptions
  alias Aurora.Uix.Stack

  @action_groups Action.action_groups()

  @doc """
  Assigns a new entity to the socket based on related parameters.

  ## Parameters
  - socket (Phoenix.LiveView.Socket.t()) - The LiveView socket
  - params (map()) - Map containing optional related_key and parent_id for relationships
  - default (struct()) - Default entity struct for new records

  ## Returns
  - Phoenix.LiveView.Socket.t()
  """
  @spec assign_new_entity(Phoenix.LiveView.Socket.t(), map(), struct()) ::
          Phoenix.LiveView.Socket.t()
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
    |> maybe_set_related_to_new_entity(socket, parent_id, default)
  end

  def assign_new_entity(socket, _params, default) do
    assign_auix(socket, :entity, default)
  end

  @doc """
  Assigns parsed options to the auix assigns map in the socket.

  ## Parameters
  - socket (Phoenix.LiveView.Socket.t()) - The LiveView socket
  - parsed_opts (map()) - Options to merge with existing auix assigns

  ## Returns
  - Phoenix.LiveView.Socket.t()
  """
  @spec assign_parsed_opts(Phoenix.LiveView.Socket.t(), map()) :: Phoenix.LiveView.Socket.t()
  def assign_parsed_opts(socket, parsed_opts) do
    socket.assigns
    |> Map.get(:auix, %{})
    |> then(&Map.merge(parsed_opts, &1))
    |> then(&assign(socket, :auix, &1))
  end

  @doc """
  Assigns a value to the auix assigns map in the socket.

  ## Parameters
  - socket (Phoenix.LiveView.Socket.t()) - The LiveView socket
  - key (atom()) - Key for storing in auix map
  - value (term()) - Value to store

  ## Returns
  - Phoenix.LiveView.Socket.t()
  """
  @spec assign_auix(Phoenix.LiveView.Socket.t(), atom(), term()) :: Phoenix.LiveView.Socket.t()
  def assign_auix(socket, key, value) do
    socket.assigns
    |> Map.get(:auix, %{})
    |> Map.put(key, value)
    |> then(&assign(socket, :auix, &1))
  end

  @doc """
  Assigns a value to the auix assigns map in the socket only if it does not exist.

  ## Parameters
  - socket (Phoenix.LiveView.Socket.t()) - The LiveView socket
  - key (atom()) - Key for storing in auix map
  - value (term()) - Value to store

  ## Returns
  - Phoenix.LiveView.Socket.t()
  """
  @spec assign_auix_new(Phoenix.LiveView.Socket.t(), atom, any) :: Phoenix.LiveView.Socket.t()
  def assign_auix_new(socket, key, value) do
    socket.assigns
    |> Map.get(:auix, %{})
    |> Map.put_new(key, value)
    |> then(&assign(socket, :auix, &1))
  end

  @doc """
  Assigns section configuration to auix assigns map.

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
    assigns.auix
    |> Map.get(:_sections)
    |> Map.put(sections_id, tab_id)
    |> then(&assign_auix(socket, :_sections, &1))
  end

  @doc """
  Extracts and assigns the current path out of the current url, to the auix map.

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
  - `socket` (Phoenix.LiveView.Socket.t()) - The LiveView socket.
  - `params` (map()) - Parameters, may contain `"routing_stack"` as a key.
  - `default_route` (map() | nil) - Optional default route to use if no stack is present.

  ## Returns
  Phoenix.LiveView.Socket.t() - The socket with updated routing stack.

  ## Examples

      iex> params = %{"routing_stack" => encoded_stack}
      iex> assign_auix_routing_stack(socket, params, nil)
      #=> %Phoenix.LiveView.Socket{assigns: %{routing_stack: %Stack{...}}}

      iex> assign_auix_routing_stack(socket, %{}, nil)
      #=> %Phoenix.LiveView.Socket{assigns: %{routing_stack: %Stack{}}}

      iex> assign_auix_routing_stack(socket, %{}, %{path: "/default"})
      #=> %Phoenix.LiveView.Socket{assigns: %{routing_stack: %Stack{...}}}

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
    |> then(&assign_auix(socket, :routing_stack, &1))
  end

  def assign_auix_routing_stack(socket, _params, nil) do
    assign_auix(socket, :routing_stack, Stack.new())
  end

  def assign_auix_routing_stack(socket, _params, default_route) do
    default_route
    |> Stack.new()
    |> then(&assign_auix(socket, :routing_stack, &1))
  end

  @doc """
  Assigns a layout option to the socket's assigns using the LayoutOptions module.

  Retrieves the option value using `LayoutOptions.get/2`. If the option is not found, assigns the
  socket unchanged. Otherwise, stores the value in the `:layout_options` key within the `auix` map.

  ## Parameters
  - `socket` (Phoenix.LiveView.Socket.t()) - The LiveView socket.
  - `option` (atom()) - The option key to retrieve and assign.

  ## Returns
  Phoenix.LiveView.Socket.t() - The socket with the option assigned in `auix.layout_options`.

  """
  @spec assign_auix_option(Phoenix.LiveView.Socket.t() | map(), atom()) ::
          Phoenix.LiveView.Socket.t() | map()
  def assign_auix_option(%Phoenix.LiveView.Socket{assigns: assigns} = socket, option)
      when is_atom(option) do
    option_value =
      case LayoutOptions.get(assigns, option) do
        {:not_found, _option} ->
          nil

        {:ok, value} ->
          value
      end

    socket
    |> assign_auix_new(:layout_options, %{})
    |> put_in([Access.key!(:assigns), :auix, :layout_options, option], option_value)
  end

  def assign_auix_option(%{auix: auix} = assigns, option) when is_atom(option) do
    option_value =
      case LayoutOptions.get(assigns, option) do
        {:not_found, _option} ->
          nil

        {:ok, value} ->
          value
      end

    auix
    |> Map.put_new(:layout_options, %{})
    |> then(&Map.put(assigns, :auix, &1))
    |> put_in([:auix, :layout_options, option], option_value)
  end

  @doc """
  Sets a layout option to the auix entry in the socket's assigns.

  ## Parameters
  - `socket` (Phoenix.LiveView.Socket.t()) - The LiveView socket.
  - `option` (atom()) - The option key to retrieve and assign.
  - `option_value` term() - The value to put on the option.

  ## Returns
  Phoenix.LiveView.Socket.t() - The updated socket.

  """
  @spec assign_auix_option(Phoenix.LiveView.Socket.t(), atom(), term() | nil) ::
          Phoenix.LiveView.Socket.t()
  def assign_auix_option(socket, option, option_value)
      when is_atom(option) do
    socket
    |> assign_auix_new(:layout_options, %{})
    |> put_in([Access.key!(:assigns), :auix, :layout_options, option], option_value)
  end

  @doc """
  Adds an action to the specified actions group in the assigns map.

  ## Parameters
  - `assigns` (map()) - The assigns map containing the `:auix` key.
  - `actions_group` (atom()) - The group to which the action will be added.
  - `action` (Action.t()) - The action to add.

  ## Returns
  map() - The updated assigns map with the action added to the group.

  ## Examples

      iex> assigns = %{auix: %{index_row_actions: []}}
      iex> action = %Aurora.Uix.Action{name: "edit", function_component: fn -> :ok end}
      iex> Aurora.Uix.Web.Templates.Basic.Helpers.add_auix_action(assigns, :index_row_actions, action)
      %{auix: %{index_row_actions: [%Aurora.Uix.Action{name: "edit", function_component: #Function<...>}]}}
  """
  @spec add_auix_action(map(), atom(), Action.t()) :: map()
  def add_auix_action(%{auix: auix} = assigns, actions_group, action)
      when actions_group in @action_groups do
    auix
    |> Map.get(actions_group, [])
    |> Enum.reverse()
    |> then(&[action | &1])
    |> Enum.reverse()
    |> then(&put_in(assigns, [:auix, actions_group], &1))
  end

  @doc """
  Inserts an action at the beginning of the specified actions group in the assigns map.

  ## Parameters
  - `assigns` (map()) - The assigns map containing the `:auix` key.
  - `actions_group` (atom()) - The group to which the action will be added.
  - `action` (Action.t()) - The action to insert.

  ## Returns
  map() - The updated assigns map with the action inserted at the beginning of the group.

  ## Examples

      iex> assigns = %{auix: %{index_row_actions: [%Aurora.Uix.Action{name: "edit"}]}}
      iex> action = %Aurora.Uix.Action{name: "delete"}
      iex> Aurora.Uix.Web.Templates.Basic.Helpers.insert_auix_action(assigns, :index_row_actions, action)
      %{auix: %{index_row_actions: [%Aurora.Uix.Action{name: "delete"}, %Aurora.Uix.Action{name: "edit"}]}}
  """
  @spec insert_auix_action(map(), atom(), Action.t()) :: map()
  def insert_auix_action(%{auix: auix} = assigns, actions_group, action)
      when actions_group in @action_groups do
    auix
    |> Map.get(actions_group, [])
    |> then(&[action | &1])
    |> then(&put_in(assigns, [:auix, actions_group], &1))
  end

  @doc """
  Replaces an action by name in the specified actions group in the assigns map.

  ## Parameters
  - `assigns` (map()) - The assigns map containing the `:auix` key.
  - `actions_group` (atom()) - The group in which the action will be replaced.
  - `action` (Action.t()) - The action to replace, must include a `:name` key.

  ## Returns
  map() - The updated assigns map with the action replaced.

  ## Examples

      iex> assigns = %{auix: %{index_row_actions: [%Aurora.Uix.Action{name: :edit}, %Aurora.Uix.Action{name: :delete}]}}
      iex> action = %Aurora.Uix.Action{name: :edit, function_component: fn -> :ok end}
      iex> Aurora.Uix.Web.Templates.Basic.Helpers.replace_auix_action(assigns, :index_row_actions, action)
      %{auix: %{index_row_actions: [%Aurora.Uix.Action{name: :edit, function_component: #Function<...>}, %Aurora.Uix.Action{name: :delete}]}}
  """
  @spec replace_auix_action(map(), atom(), Action.t()) :: map()
  def replace_auix_action(%{auix: auix} = assigns, actions_group, %{name: action_name} = action)
      when actions_group in @action_groups do
    auix
    |> Map.get(actions_group, [])
    |> Enum.map(fn
      %{name: ^action_name} -> action
      current_action -> current_action
    end)
    |> then(&put_in(assigns, [:auix, actions_group], &1))
  end

  @doc """
  Removes an action by name from the specified actions group in the assigns map.

  ## Parameters
  - `assigns` (map()) - The assigns map containing the `:auix` key.
  - `actions_group` (atom()) - The group from which the action will be removed.
  - `action_name` (atom()) - The name of the action to remove.

  ## Returns
  map() - The updated assigns map with the action removed from the group.

  ## Examples

      iex> assigns = %{auix: %{index_row_actions: [{:edit, fn -> :ok end}, {:delete, fn -> :ok end}]}}
      iex> Aurora.Uix.Web.Templates.Basic.Helpers.remove_auix_action(assigns, :index_row_actions, :edit)
      %{auix: %{index_row_actions: [{:delete, #Function<...>}]}}
  """
  @spec remove_auix_action(map(), atom(), atom()) :: map()
  def remove_auix_action(%{auix: auix} = assigns, actions_group, action_name)
      when actions_group in @action_groups do
    auix
    |> Map.get(actions_group, [])
    |> Enum.reject(&(&1.name == action_name))
    |> then(&put_in(assigns, [:auix, actions_group], &1))
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
        %{assigns: %{auix: %{_current_path: current_path}}} = socket,
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
  def auix_route_back(%{assigns: %{auix: %{routing_stack: routing_stack}}} = socket) do
    {new_navigation_stack, back_path} = Stack.pop!(routing_stack)

    socket
    |> assign_auix(:routing_stack, new_navigation_stack)
    |> route_to(Map.new(back_path))
  end

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
  def get_field(%{name: field_key} = field, configurations, resource_name) do
    configurations
    |> Map.get(resource_name, %{})
    |> Map.get(:resource_config, %{})
    |> Map.get(:fields, %{})
    |> Map.get(field_key, Field.new(%{key: field_key, resource: resource_name}))
    |> Field.change(Map.get(field, :config, []))
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
    |> Enum.map(&get_field(%{name: &1}, parsed_opts.configurations, parsed_opts.resource_name))
    |> Enum.filter(&(&1.type in [:many_to_one_association, :one_to_many_association]))
    |> Enum.map(&{&1.type, &1.key})
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
  @spec flatten_layout_tree(map() | list(), list()) :: list()
  def flatten_layout_tree(elements, result \\ [])
  def flatten_layout_tree([], result), do: result

  def flatten_layout_tree(%{inner_elements: inner_elements} = layout_tree, result) do
    flatten_layout_tree(inner_elements, [
      %{tag: layout_tree.tag, name: layout_tree[:name]} | result
    ])
  end

  def flatten_layout_tree([%{inner_elements: inner_elements} | rest], result) do
    inner_elements
    |> Enum.reduce(
      result,
      &flatten_layout_tree(&1.inner_elements, [%{tag: &1.tag, name: &1[:name]} | &2])
    )
    |> then(&flatten_layout_tree(rest, &1))
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

  @doc """
  Safely converts a binary to an existing atom.

  ## Parameters
  - `name` (`term()` | `nil`) - The name to convert to an atom.

  ## Returns
  `atom()` | `nil` - The existing atom if it exists, otherwise nil.

  """
  @spec safe_existing_atom(term() | nil) :: atom() | nil
  def safe_existing_atom(name) when is_binary(name) do
    String.to_existing_atom(name)
  catch
    _ -> nil
  end

  def safe_existing_atom(name) when is_atom(name), do: name

  def safe_existing_atom(_name), do: nil

  @doc """
  Gets the value of an entity's primary key.

  ## Parameters
  - `entity` (term()) - The entity that will be primary key value.
  - `primary_key` (atom() | list()) - The field (or fields) to be gather from the entity.

  ## Returns
  `term()` | list() | nil - Return a single value if the primary key is an `atom()` or a single element list.
    Otherwise returns a list of values, each corresponding to each of the primary key list of fields.
  """
  @spec primary_key_value(term() | nil, atom() | list()) :: term() | list() | nil
  def primary_key_value(entity, _primary_key) when is_nil(entity), do: nil

  def primary_key_value(entity, primary_key) when is_atom(primary_key) do
    Map.get(entity, primary_key)
  end

  def primary_key_value(entity, [primary_key]) do
    Map.get(entity, primary_key)
  end

  def primary_key_value(entity, primary_keys) do
    Enum.map(primary_keys, &Map.get(entity, &1))
  end

  ## PRIVATE
  @spec maybe_set_related_to_new_entity(
          binary | nil,
          Phoenix.LiveView.Socket.t(),
          binary | nil,
          struct
        ) :: Phoenix.LiveView.Socket.t()
  defp maybe_set_related_to_new_entity(related_key, socket, parent_id, default)
       when is_nil(related_key) or is_nil(parent_id),
       do: assign_auix(socket, :entity, default)

  defp maybe_set_related_to_new_entity(related_key, socket, parent_id, default) do
    default
    |> struct(%{related_key => parent_id})
    |> then(&assign_auix(socket, :entity, &1))
  end

  # Adds a path to the forward navigation stack and updates last route path in assigns
  @spec add_forward_path(Phoenix.LiveView.Socket.t(), binary(), keyword()) ::
          Phoenix.LiveView.Socket.t()
  defp add_forward_path(%{assigns: %{auix: %{routing_stack: stack}}} = socket, path, navigation) do
    navigation_entry =
      navigation
      |> route_type()
      |> then(&%{type: &1, path: path})

    stack
    |> Stack.push(navigation_entry)
    |> then(&assign_auix(socket, :routing_stack, &1))
    |> assign_auix(:_last_route_path, path)
  end

  defp add_forward_path(socket, _path, _navigation), do: socket

  # Handles route changes based on navigation type and current routing stack
  @spec route_to(Phoenix.LiveView.Socket.t(), map() | keyword()) :: Phoenix.LiveView.Socket.t()
  defp route_to(%{assigns: %{auix: %{routing_stack: stack}}} = socket, %{
         type: :navigate,
         path: path
       }) do
    push_navigate(socket, to: route_path_with_stack(path, stack))
  end

  defp route_to(%{assigns: %{auix: %{routing_stack: stack}}} = socket, %{
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
    |> :zlib.compress()
    |> Base.encode64()
    |> URI.encode_www_form()
  end

  # Decodes an obfuscated routing stack string back into a stack struct
  @spec decode_routing_stack(binary()) :: struct()
  defp decode_routing_stack(obfuscated) do
    obfuscated
    |> Base.decode64!()
    |> :zlib.uncompress()
    |> Jason.decode!()
    |> Map.get("values", [])
    |> Enum.map(&%{path: &1["path"], type: String.to_existing_atom(&1["type"])})
    |> Stack.new()
  end
end
