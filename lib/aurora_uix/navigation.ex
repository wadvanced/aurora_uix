defmodule Aurora.Uix.Navigation do
  @moduledoc """
  Navigation state of a generated Aurora UIX view, as plain data.

  ## Key Features

  - One `%Aurora.Uix.Navigation{}` struct with six fields: `base_path`, `current_path`,
    `uri_path`, `uri_path_id`, `stack` and `last_route_path`
  - Resolves the resource `uri_path` from an explicit `base_path` or from the `current_path`
  - Builds the five resource paths: index, new, show, edit and show-edit
  - `forward/2`, `back/1` and `back_to_edit/2` return the new struct and the route to follow
  - Encodes and decodes the routing stack carried in the `routing_stack` query parameter

  ## Key Constraints

  - Every function takes the struct and returns data; none takes a socket
  - Backend-agnostic: it references no Ecto and no Ash module
  - The struct has no navigation mode; an unknown key given to `new/1` raises `KeyError`
  - `forward/2` requires a binary `current_path`
  """

  alias Aurora.Uix.Stack

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

  @type route() :: %{type: :patch | :navigate, path: binary()}

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
  Sets `current_path` to the path component of a url.

  ## Parameters

  - `nav` (t()) - The navigation struct.
  - `url` (binary() | URI.t() | nil) - Actual url.

  ## Returns

  t() - The navigation struct with `current_path` set.
  """
  @spec put_current_path(t(), binary() | URI.t() | nil) :: t()
  def put_current_path(%__MODULE__{} = nav, url),
    do: %{nav | current_path: url |> URI.parse() |> Map.get(:path)}

  @doc """
  Replaces the routing stack of a navigation struct.

  ## Parameters

  - `nav` (t()) - The navigation struct.
  - `stack` (Aurora.Uix.Stack.t()) - The new routing stack.

  ## Returns

  t() - The navigation struct with `stack` set.
  """
  @spec put_stack(t(), Stack.t()) :: t()
  def put_stack(%__MODULE__{} = nav, %Stack{} = stack), do: %{nav | stack: stack}

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
  Moves forward, pushing the current path on the routing stack.

  ## Parameters

  - `nav` (t()) - The navigation struct; its `current_path` must be a binary.
  - `target` (keyword()) - `[to: path]` to navigate, or `[patch: path]` to patch.

  ## Returns

  {t(), route()} - The struct with the pushed stack and `last_route_path` set, and the route
  to follow, its path carrying the encoded stack.
  """
  @spec forward(t(), keyword()) :: {t(), route()}
  def forward(%__MODULE__{current_path: current_path} = nav, target)
      when is_binary(current_path) do
    %{type: type, path: path} = target_route(target)
    stack = Stack.push(nav.stack, %{type: type, path: current_path})

    {%{nav | stack: stack, last_route_path: current_path},
     %{type: type, path: route_path_with_stack(path, stack)}}
  end

  @doc """
  Moves back, popping the last route from the routing stack.

  When the stack is empty, or its top is the current path, it falls back to the index path
  derived from the current path.

  ## Parameters

  - `nav` (t()) - The navigation struct.

  ## Returns

  {t(), route()} - The struct with the popped stack, and the route to follow, its path
  carrying the encoded stack.
  """
  @spec back(t()) :: {t(), route()}
  def back(%__MODULE__{} = nav) do
    current_path = nav.current_path || ""
    fallback_route = determine_fallback_path(current_path)
    {stack, popped_route} = Stack.pop(nav.stack, fallback_route)

    %{type: type, path: path} =
      if current_path == popped_route.path, do: fallback_route, else: popped_route

    {%{nav | stack: stack}, %{type: type, path: route_path_with_stack(path, stack)}}
  end

  @doc """
  Moves back to the edit path of a record, under the path the user came from.

  Pops the origin entry of the stack and goes back to `<origin path>/<id>/edit`.

  ## Parameters

  - `nav` (t()) - The navigation struct; its stack must not be empty.
  - `id` (term()) - The record id.

  ## Returns

  {t(), route()} - The struct with the stack without the origin entry, and the route to the
  edit path.
  """
  @spec back_to_edit(t(), term()) :: {t(), route()}
  def back_to_edit(%__MODULE__{} = nav, id) do
    {stack, origin} = Stack.pop!(nav.stack)

    edit_path =
      origin
      |> Map.get(:path)
      |> URI.parse()
      |> Map.get(:path)
      |> then(&"#{&1}/#{id}/edit")

    back(%{nav | stack: Stack.push(stack, %{type: :navigate, path: edit_path})})
  end

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

  @spec put_uri_path(t(), binary()) :: t()
  defp put_uri_path(nav, uri_path),
    do: %{nav | uri_path: uri_path, uri_path_id: String.replace(uri_path, "/", "--")}

  @spec target_route(keyword()) :: route()
  defp target_route(to: path), do: %{type: :navigate, path: path}
  defp target_route(patch: path), do: %{type: :patch, path: path}

  # Builds a complete path with routing stack encoded as a query parameter
  @spec route_path_with_stack(binary(), Stack.t()) :: binary()
  defp route_path_with_stack(path, routing_stack) do
    query_parameter_separator = if String.contains?(path, "?"), do: "&", else: "?"

    routing_stack
    |> encode_stack()
    |> then(&"#{path}#{query_parameter_separator}routing_stack=#{&1}")
  end

  @spec determine_fallback_path(binary()) :: route()
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
