defmodule AuroraUixWeb.Uix.CreateUI.IndexUI do
  @moduledoc """
  Provides compile-time macros for defining and managing index-based UI structures.

  ## Key Features
  - Declarative index field configuration
  - Compile-time field registration
  - Flexible index view generation

  ## Compilation Process
  1. Fields are registered using `index_columns/2`
  2. Module attributes are populated
  3. Layout paths are automatically generated during compilation

  """
  @doc false
  defmacro __using__(_) do
    quote do
      import AuroraUixWeb.Uix.CreateUI.IndexUI

      @before_compile AuroraUixWeb.Uix.CreateUI.IndexUI
    end
  end

  @doc false
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
  Registers index columns for a specific resource.

  ## Parameters
  - `name` (atom): Unique identifier for the index configuration
  - `fields` (list): List of field names to display in the index view

  ## Behavior
  - Accumulates fields for the specified resource name
  - Allows multiple calls to append additional fields
  - Processed during module compilation

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
