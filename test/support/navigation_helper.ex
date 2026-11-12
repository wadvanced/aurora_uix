defmodule Aurora.UixWeb.Test.NavigationHelper do
  @moduledoc """
  Reads and builds the `routing_stack` query parameter that generated LiveViews carry on
  every patch and live redirect, so navigation tests can assert on the decoded stack.

  ## Key Features

  - `decode_route/1` splits a path into its path, its remaining query parameters and the
    decoded routing stack.
  - `encode_stack/1` builds a `routing_stack` parameter value from a list of entries.

  ## Key Constraints

  - Self-contained: it reimplements the wire format instead of calling library code, so the
    tests that use it keep their meaning when the library's navigation code moves.
  - Stack entries are written top first as `{type, path}` tuples.
  """

  @doc """
  Decodes a navigation target into `{path, query, stack}`.

  ## Parameters
  - `path` (binary()) - A path as received from `assert_patch/1` or a live redirect.

  ## Returns
  `{binary(), map(), list({atom(), binary()}) | :none}` - The path without query, the query
  parameters without `"routing_stack"`, and the decoded stack, or `:none` when the path
  carries no `routing_stack` parameter.
  """
  @spec decode_route(binary()) :: {binary(), map(), list({atom(), binary()}) | :none}
  def decode_route(path) do
    uri = URI.parse(path)
    {param, query} = uri.query |> to_string() |> URI.decode_query() |> Map.pop("routing_stack")
    {uri.path, query, decode_param(param)}
  end

  @doc """
  Encodes a list of stack entries as a `routing_stack` parameter value.

  ## Parameters
  - `entries` (list({atom(), binary()})) - Stack entries, top first.

  ## Returns
  binary() - The URL-encoded parameter value.
  """
  @spec encode_stack(list({atom(), binary()})) :: binary()
  def encode_stack(entries) do
    %{values: Enum.map(entries, fn {type, path} -> %{type: type, path: path} end)}
    |> Jason.encode!()
    |> :zlib.compress()
    |> Base.encode64()
    |> URI.encode_www_form()
  end

  @spec decode_param(binary() | nil) :: list({atom(), binary()}) | :none
  defp decode_param(nil), do: :none

  defp decode_param(param) do
    param
    |> Base.decode64!()
    |> :zlib.uncompress()
    |> Jason.decode!()
    |> Map.fetch!("values")
    |> Enum.map(fn %{"type" => type, "path" => path} -> {String.to_existing_atom(type), path} end)
  end
end
