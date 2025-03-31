defmodule AuroraUixWeb.Templates.Core.Helpers do
  @moduledoc """
  Provides helper functions and macros for managing LiveView components and templates
  in the AuroraUixWeb application.
  """

  @doc """
  Dynamically generates a module with helper functions for LiveView components.

  ## Parameters
    - `modules` (map): A map containing module dependencies.
    - `:aurora_core_helpers` (atom): The atom specifying the helper type.
    - `_parsed_opts` (map): Additional options for customization.

  ## Returns
    - `Macro.t()`: A quoted expression defining the generated module.
  """
  @spec generate_module(map, atom, map) :: Macro.t()
  def generate_module(modules, :aurora_core_helpers, _parsed_opts) do
    aurora_core_helpers = AuroraUixWeb.Core.Helpers

    quote do
      defmodule unquote(aurora_core_helpers) do
        @moduledoc false

        use unquote(modules.web), :live_component
        import AuroraUixWeb.Template, only: [safe_existing_atom: 1]

        alias Phoenix.LiveView.JS

        @doc false
        def assign_new_entity(
              socket,
              %{"related_key" => related_key, "parent_id" => parent_id},
              default
            ) do
          related_key
          |> safe_existing_atom()
          |> __maybe_set_related_to_new_entity__(socket, parent_id, default)
        end

        def assign_new_entity(socket, params, default) do
          assign(socket, :auix_entity, default)
        end

        @doc false
        @spec assign_source(Phoenix.LiveView.Socket.t(), map, binary) ::
                Phoenix.LiveView.Socket.t()
        def assign_source(socket, params, default_source) do
          params
          |> Map.get("source")
          |> __maybe_set_different_source_and_link__(socket, default_source)
        end

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
                |> String.replace("[[entity]]", id)
                |> then(&navigate/1)
              end

          assign_auix(socket, :index_row_click, index_row_click)
        end

        @spec assign_auix(Phoenix.LiveView.Socket.t(), atom, any) :: Phoenix.LiveView.Socket.t()
        def assign_auix(socket, key, value) do
          socket.assigns
          |> Map.get(:_auix, %{})
          |> Map.put(key, value)
          |> then(&assign(socket, :_auix, &1))
        end

        @spec index_show_entity_link(binary, map) :: binary
        def index_show_entity_link(auix, entity) do
          auix
          |> Map.get(:index_show_entity_link, "#")
          |> String.replace("[[entity]]", Map.get(entity, :id))
          |> then(fn link -> URI.decode("/#{link}") end)
        end

        def related_path(source, _auix_entity, nil, _owner_key), do: ""
        def related_path(source, _auix_entity, _related_key, nil), do: ""
        def related_path(source, %{id: nil}, _related_key, _owner_key), do: ""

        def related_path(source, %{id: id} = auix_entity, related_key, owner_key) do
          "source=#{source}/#{id}&related_key=#{related_key}&parent_id=#{Map.get(auix_entity, owner_key)}"
        end

        def related_path(_parsed_opts, _auix_entity, _related_key, _owner_key), do: ""

        ## Non imported
        @doc false
        @spec __maybe_set_related_to_new_entity__(
                Phoenix.LiveView.Socket.t(),
                binary | nil,
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
          ~p"/#{uri}"
          |> URI.decode()
          |> JS.navigate()
        end
      end
    end
  end
end
