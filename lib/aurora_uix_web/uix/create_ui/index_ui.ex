defmodule AuroraUixWeb.Uix.CreateUI.IndexUI do
  @moduledoc """
  Provides macros for defining index-based UI structures in AuroraUix.

  This module allows defining and managing index views using compile-time attributes. It provides macros to
  register index fields and compile them into a structured format for later use in UI generation.
  """

  defmacro __using__(_) do
    quote do
      import AuroraUixWeb.Uix.CreateUI.IndexUI

      @before_compile AuroraUixWeb.Uix.CreateUI.IndexUI
    end
  end

  defmacro __before_compile__(env) do
    env.module
    |> Module.get_attribute(:_auix_index_fields, %{})
    |> Enum.each(fn {name, fields} ->
      Module.put_attribute(env.module, :_auix_layout_paths, %{
        tag: :index,
        name: name,
        state: :start,
        opts: [],
        config: {:fields, fields}
      })

      Module.put_attribute(env.module, :_auix_layout_paths, %{
        tag: :index,
        name: name,
        state: :end
      })
    end)

    Module.delete_attribute(env.module, :_auix_index_fields)
    :ok
  end

  @doc """
  Registers a set of fields for an index under the given `name`.

  This macro stores the provided fields in the module attribute `:_auix_index_fields`,
  allowing them to be processed later during compilation. The fields are accumulated,
  meaning multiple calls to `index/2` with the same `name` will append the fields instead
  of overwriting them.

  ## Parameters

  - `name` (`atom`) - The identifier for the index (e.g., `:products`, `:users`).
  - `fields` (`list(atom)`) - A list of field names to include in the index.
  """
  @spec index_columns(atom, list) :: Macro.t()
  defmacro index_columns(name, fields) do
    registration =
      quote do
        fields_map = Module.get_attribute(__MODULE__, :_auix_index_fields, %{})

        fields_map
        |> Map.get(unquote(name), [])
        |> Kernel.++(unquote(fields))
        |> then(&Map.put(fields_map, unquote(name), &1))
        |> then(&Module.put_attribute(__MODULE__, :_auix_index_fields, &1))
      end

    quote do
      unquote(registration)
    end
  end
end
