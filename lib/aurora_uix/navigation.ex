defmodule Aurora.Uix.Navigation do
  @moduledoc """
  Navigation state and helpers for the generated Aurora UIX views.

  The state lives in one struct, stored at `auix.navigation`. `put/2` also mirrors it into
  the legacy `auix` keys (`routing_stack`, `uri_path`, `uri_path_id`, `_current_path` and
  `_last_route_path`) that templates and host code read.

  ## Key Features

  - One `%Aurora.Uix.Navigation{}` struct holding base path, current path, URI path, routing
    stack and last route path
  - Resolves the resource `uri_path` from an explicit `base_path` or from the current path
  - Builds the index, new, show, edit and show-edit paths of a resource
  - Forward and back navigation through the routing stack, carried in the `routing_stack`
    query parameter
  - Encodes and decodes the routing stack parameter

  ## Key Constraints

  - Backend-agnostic: it references no Ecto and no Ash module
  - The struct has no navigation mode; an unknown key given to `new/1` raises `KeyError`
  - The legacy `auix` keys are written only by `put/2`; assigning one of them directly does
    not change navigation
  - `forward/3` requires a binary `current_path`
  """

  import Phoenix.LiveView, only: [push_navigate: 2, push_patch: 2]

  alias Aurora.Uix.Stack
  alias Aurora.Uix.Templates.Basic.Helpers, as: BasicHelpers
  alias Phoenix.LiveView.Socket

  defstruct base_path: nil,
            current_path: nil,
            uri_path: nil,
            uri_path_id: nil,
            stack: %Stack{},
            last_route_path: nil

  @type t() :: %__MODULE__{
          base_path: binary() | nil,
          current_path: binary() | nil,
          uri_path: binary() | nil,
          uri_path_id: binary() | nil,
          stack: Stack.t(),
          last_route_path: binary() | nil
        }

  @doc """
  Creates a navigation struct.

  ## Parameters

  - `opts` (keyword()) - Struct fields. An unknown key raises `KeyError`.

  ## Returns

  t() - The navigation struct.
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []), do: struct!(__MODULE__, opts)

  @doc """
  Reads the navigation struct of a socket.

  ## Parameters

  - `socket` (Phoenix.LiveView.Socket.t()) - The LiveView socket.

  ## Returns

  t() - The struct at `auix.navigation`, or `new()` when the key is absent.
  """
  @spec get(Socket.t()) :: t()
  def get(socket) do
    case socket.assigns.auix[:navigation] do
      %__MODULE__{} = nav -> nav
      nil -> new()
    end
  end

  @doc """
  Stores the navigation struct at `auix.navigation` and mirrors it into the legacy keys.

  `auix.routing_stack` is always written. `auix.uri_path`, `auix.uri_path_id`,
  `auix._current_path` and `auix._last_route_path` are written only when the matching struct
  field is not `nil`.

  ## Parameters

  - `socket` (Phoenix.LiveView.Socket.t()) - The LiveView socket.
  - `nav` (t()) - The navigation struct.

  ## Returns

  Phoenix.LiveView.Socket.t() - Socket with updated auix assigns.
  """
  @spec put(Socket.t(), t()) :: Socket.t()
  def put(socket, %__MODULE__{} = nav) do
    socket
    |> BasicHelpers.assign_auix(:navigation, nav)
    |> BasicHelpers.assign_auix(:routing_stack, nav.stack)
    |> maybe_assign(:uri_path, nav.uri_path)
    |> maybe_assign(:uri_path_id, nav.uri_path_id)
    |> maybe_assign(:_current_path, nav.current_path)
    |> maybe_assign(:_last_route_path, nav.last_route_path)
  end

  @doc """
  Extracts the path of the current url and stores it as the navigation `current_path`.

  ## Parameters

  - `socket` (Phoenix.LiveView.Socket.t()) - The LiveView socket.
  - `url` (binary() | URI.t() | nil) - Actual url.

  ## Returns

  Phoenix.LiveView.Socket.t() - Socket with updated navigation.
  """
  @spec assign_current_path(Socket.t(), binary() | URI.t() | nil) :: Socket.t()
  def assign_current_path(socket, url) do
    put(socket, %{get(socket) | current_path: url |> URI.parse() |> Map.get(:path)})
  end

  @doc """
  Resolves `uri_path` and `uri_path_id` of a navigation struct.

  With a binary `base_path`, `uri_path` is the base path without its leading `/`. Otherwise
  it is derived from `current_path`, dropping the record id and the action suffix for the
  `:edit`, `:show` and `:show_edit` live actions.

  ## Parameters

  - `nav` (t()) - The navigation struct.
  - `live_action` (atom() | nil) - The current live action.

  ## Returns

  t() - The navigation struct with `uri_path` and `uri_path_id` set.
  """
  @spec resolve_uri_path(t(), atom() | nil) :: t()
  def resolve_uri_path(%__MODULE__{base_path: base_path} = nav, _live_action)
      when is_binary(base_path) do
    base_path
    |> String.replace_leading("/", "")
    |> then(&put_uri_path(nav, &1))
  end

  def resolve_uri_path(%__MODULE__{} = nav, live_action) do
    all_paths =
      nav.current_path
      |> String.replace_leading("/", "")
      |> String.replace_trailing("/edit", "")
      |> String.replace_trailing("/show", "")
      |> String.replace_trailing("/show-edit", "")
      |> String.split("/")
      |> Enum.reverse()

    reverse_paths =
      case {live_action, all_paths} do
        {:edit, [_ | paths]} -> paths
        {:show, [_ | paths]} -> paths
        {:show_edit, [_ | paths]} -> paths
        {_, paths} -> paths
      end

    uri_path =
      reverse_paths
      |> Enum.reverse()
      |> Enum.join("/")

    put_uri_path(nav, uri_path)
  end

  @doc """
  Resolves the `uri_path` of the socket's navigation from its live action, and stores it.

  ## Parameters

  - `socket` (Phoenix.LiveView.Socket.t()) - The LiveView socket.

  ## Returns

  Phoenix.LiveView.Socket.t() - Socket with updated navigation.
  """
  @spec assign_uri_path(Socket.t()) :: Socket.t()
  def assign_uri_path(socket) do
    put(socket, resolve_uri_path(get(socket), socket.assigns[:live_action]))
  end

  @doc """
  Assigns the routing stack. Decodes it from the `"routing_stack"` parameter, or starts it from
  the default route.

  ## Parameters

  - `socket` (Phoenix.LiveView.Socket.t()) - The LiveView socket.
  - `params` (map()) - Parameters, may contain `"routing_stack"` as a key.
  - `default_route` (map() | nil) - Optional default route to use if no stack is present.

  ## Returns

  Phoenix.LiveView.Socket.t() - Socket with updated navigation.
  """
  @spec assign_stack(Socket.t(), map(), map() | nil) :: Socket.t()
  def assign_stack(socket, params, default_route \\ nil)

  def assign_stack(socket, %{"routing_stack" => encoded_routing_stack}, _default_route) do
    encoded_routing_stack
    |> decode_stack()
    |> then(&put(socket, %{get(socket) | stack: &1}))
  end

  def assign_stack(socket, _params, nil) do
    put(socket, %{get(socket) | stack: Stack.new()})
  end

  def assign_stack(socket, _params, default_route) do
    default_route
    |> Stack.new()
    |> then(&put(socket, %{get(socket) | stack: &1}))
  end

  @doc """
  Builds a resource path from the navigation `uri_path`.

  ## Parameters

  - `nav` (t()) - The navigation struct.
  - `action` (:index | :new | :show | :edit | :show_edit) - The target action.
  - `id` (term()) - The record id, for `:show`, `:edit` and `:show_edit`.

  ## Returns

  binary() - The path.
  """
  @spec path(t(), :index | :new | :show | :edit | :show_edit, term()) :: binary()
  def path(nav, action, id \\ nil)
  def path(%__MODULE__{uri_path: uri_path}, :index, _id), do: "/#{uri_path}"
  def path(%__MODULE__{uri_path: uri_path}, :new, _id), do: "/#{uri_path}/new"
  def path(%__MODULE__{uri_path: uri_path}, :show, id), do: "/#{uri_path}/#{id}/show"
  def path(%__MODULE__{uri_path: uri_path}, :edit, id), do: "/#{uri_path}/#{id}/edit"
  def path(%__MODULE__{uri_path: uri_path}, :show_edit, id), do: "/#{uri_path}/#{id}/show-edit"

  @doc """
  Navigates forward, pushing the current path on the routing stack.

  ## Parameters

  - `socket` (Phoenix.LiveView.Socket.t()) - The LiveView socket.
  - `nav` (t()) - The navigation struct; its `current_path` must be a binary.
  - `target` (keyword()) - `[to: path]` to navigate, or `[patch: path]` to patch.

  ## Returns

  Phoenix.LiveView.Socket.t() - Socket with updated navigation.
  """
  @spec forward(Socket.t(), t(), keyword()) :: Socket.t()
  def forward(socket, %__MODULE__{} = nav, target) when is_binary(nav.current_path) do
    stack = Stack.push(nav.stack, %{type: route_type(target), path: nav.current_path})

    socket
    |> put(%{nav | stack: stack, last_route_path: nav.current_path})
    |> route_to(stack, target)
  end

  @doc """
  Navigates back, popping the last route from the routing stack.

  When the stack is empty, or its top is the current path, it falls back to the index path
  derived from the current path.

  ## Parameters

  - `socket` (Phoenix.LiveView.Socket.t()) - The LiveView socket.
  - `nav` (t()) - The navigation struct.

  ## Returns

  Phoenix.LiveView.Socket.t() - Socket with updated navigation.
  """
  @spec back(Socket.t(), t()) :: Socket.t()
  def back(socket, %__MODULE__{} = nav) do
    current_path = nav.current_path || ""

    fallback_path = determine_fallback_path(current_path)

    {new_stack, back_path} = Stack.pop(nav.stack, fallback_path)

    calculated_back_path =
      if current_path == back_path.path,
        do: fallback_path,
        else: back_path

    socket
    |> put(%{nav | stack: new_stack})
    |> route_to(new_stack, Map.new(calculated_back_path))
  end

  @doc """
  Patches to a record path of the resource.

  ## Parameters

  - `socket` (Phoenix.LiveView.Socket.t()) - The LiveView socket.
  - `nav` (t()) - The navigation struct.
  - `id` (term()) - The record id.
  - `action` (:show | :edit | :show_edit) - The record action.

  ## Returns

  Phoenix.LiveView.Socket.t() - Socket with the patch pushed.
  """
  @spec record(Socket.t(), t(), term(), :show | :edit | :show_edit) :: Socket.t()
  def record(socket, nav, id, action), do: push_patch(socket, to: path(nav, action, id))

  @doc """
  Replaces the parent source with the related source inside a `uri_path`.

  ## Parameters

  - `uri_path` (binary()) - The parent `uri_path`.
  - `source` (binary()) - The parent source.
  - `related_source` (binary()) - The related source.

  ## Returns

  binary() - The related `uri_path`.
  """
  @spec related_uri_path(binary(), binary(), binary()) :: binary()
  def related_uri_path(uri_path, source, related_source),
    do: String.replace(uri_path, source, related_source)

  @doc """
  Encodes a routing stack into a compressed, Base64, URL-encoded string.

  ## Parameters

  - `stack` (Aurora.Uix.Stack.t()) - The routing stack.

  ## Returns

  binary() - The encoded stack.
  """
  @spec encode_stack(Stack.t()) :: binary()
  def encode_stack(stack) do
    stack
    |> Map.from_struct()
    |> Jason.encode!()
    |> :zlib.compress()
    |> Base.encode64()
    |> URI.encode_www_form()
  end

  @doc """
  Decodes a routing stack string back into a stack. Raises on a malformed value.

  ## Parameters

  - `encoded` (binary()) - The Base64 stack, already URI-decoded.

  ## Returns

  Aurora.Uix.Stack.t() - The decoded stack.
  """
  @spec decode_stack(binary()) :: Stack.t()
  def decode_stack(encoded) do
    encoded
    |> Base.decode64!()
    |> :zlib.uncompress()
    |> Jason.decode!()
    |> Map.get("values", [])
    |> Enum.map(&%{path: &1["path"], type: String.to_existing_atom(&1["type"])})
    |> Stack.new()
  end

  # PRIVATE

  @spec maybe_assign(Socket.t(), atom(), term()) :: Socket.t()
  defp maybe_assign(socket, _key, nil), do: socket
  defp maybe_assign(socket, key, value), do: BasicHelpers.assign_auix(socket, key, value)

  @spec put_uri_path(t(), binary()) :: t()
  defp put_uri_path(nav, uri_path),
    do: %{nav | uri_path: uri_path, uri_path_id: String.replace(uri_path, "/", "--")}

  # Handles route changes based on navigation type and the given routing stack
  @spec route_to(Socket.t(), Stack.t(), map() | keyword()) :: Socket.t()
  defp route_to(socket, stack, %{type: :navigate, path: path}) do
    push_navigate(socket, to: route_path_with_stack(path, stack))
  end

  defp route_to(socket, stack, %{type: :patch, path: path}) do
    push_patch(socket, to: route_path_with_stack(path, stack))
  end

  defp route_to(socket, stack, to: path),
    do: route_to(socket, stack, %{type: :navigate, path: path})

  defp route_to(socket, stack, patch: path),
    do: route_to(socket, stack, %{type: :patch, path: path})

  # Converts navigation keyword options to route type atoms
  @spec route_type(keyword()) :: atom()
  defp route_type(to: _path), do: :navigate
  defp route_type(patch: _path), do: :patch

  # Builds a complete path with routing stack encoded as a query parameter
  @spec route_path_with_stack(binary(), Stack.t()) :: binary()
  defp route_path_with_stack(path, routing_stack) do
    query_parameter_separator = if String.contains?(path, "?"), do: "&", else: "?"

    routing_stack
    |> encode_stack()
    |> then(&"#{path}#{query_parameter_separator}routing_stack=#{&1}")
  end

  @spec determine_fallback_path(binary()) :: map()
  defp determine_fallback_path(current_path) do
    path =
      cond do
        String.ends_with?(current_path, "/show-edit") ->
          remove_trailing_paths(current_path, 2)

        String.ends_with?(current_path, "/show") ->
          remove_trailing_paths(current_path, 2)

        String.ends_with?(current_path, "/edit") ->
          remove_trailing_paths(current_path, 2)

        String.ends_with?(current_path, "/new") ->
          remove_trailing_paths(current_path, 1)

        true ->
          current_path
      end

    %{type: :navigate, path: path}
  end

  @spec remove_trailing_paths(binary(), integer()) :: binary()
  defp remove_trailing_paths(current_path, count) do
    paths =
      current_path
      |> String.split("/")
      |> Enum.reverse()

    if Enum.count(paths) > count,
      do:
        paths
        |> Enum.with_index(&if &2 < count, do: nil, else: &1)
        |> Enum.reject(&is_nil/1)
        |> Enum.reverse()
        |> Enum.join("/"),
      else: List.last(paths)
  end
end
