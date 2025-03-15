defmodule AuroraUixWeb.Templates.Basic.LogicModulesGenerator do
  @moduledoc """
  Provides functionality to dynamically generate LiveView modules for CRUD operations.

  This module generates LiveView modules for `:index`, `:show`, and `:edit` views, including
  functions for rendering, mounting, handling events, and managing entity lifecycle operations
  (e.g., listing, editing, creating, and deleting entities).

  ## Key Features
  - Dynamically generates LiveView modules based on the provided context and schema.
  - Supports standard CRUD operations for entities.
  - Integrates with Ecto schemas and contexts for data access and manipulation.
  - Provides customizable templates and behavior through parsed options.

  ## Usage
  Use `generate_module/3` to create LiveView modules for specific UI types (`:index`, `:show`, `:edit`).
  The generated modules include:
  - Streamed entity listing for `:index`.
  - Entity detail views for `:show`.
  - Forms for creating and editing entities for `:edit`.

  """

  @doc """
  Generates a LiveView module definition for the specified `type`, including functions for rendering,
    mounting, and handling events and parameters.

  Basically creates the necessary functions for:
  - Initialize the socket with a streamed list of entities.
  - Handling the navigation actions.
  - Manage editing, creating, and listing views.
  - Handling deletion of entities.

  ## Parameters

    - `context` (`module`): The module that provides the data access functions, such as `list_`, `get_`, and `delete_`.
    - `module` (`module`): The Ecto schema module or context module used for data operations.
    - `type` (`atom`): Specifies the type of UI component to generate. Currently, only `:index` is supported.
    - `opts` (`Keyword.t()`): A map of options passed to customize the generated LiveView module.
    - `parsed_opts` (`map`): A map of parsed options containing precomputed values such as the source name,
    module name, and titles for use in the generated module.

  ## Returns

      - (`Macro.t()`): A quoted expression representing the generated module definition.

  ## Generated Behavior

  The function expects the provided context and module to have the following functions defined:

  - `list_<source>()` - Returns a list of all entities for streaming.
  - `get_<schema_module>!(id)` - Fetches a specific entity by its ID.
  - `delete_<schema_module>(instance)` - Deletes a specific entity.

  ## Notes

  - The generated module provides standard LiveView functionality, including dynamic assignment
  of page titles and CRUD operations for the specified schema or context module.
  """
  @spec generate_module(map, atom, map) :: Macro.t()
  def generate_module(modules, :index = type, parsed_opts) do
    parsed_opts = remove_omitted_fields(parsed_opts)

    list_key = String.to_existing_atom(parsed_opts.source)
    list_function = String.to_atom("list_#{parsed_opts.source}")
    get_function = String.to_atom("get_#{parsed_opts.module}!")
    delete_function = String.to_atom("delete_#{parsed_opts.module}")
    index_module = module_name(modules, parsed_opts, ".Index")
    form_component = module_name(modules, parsed_opts, ".FormComponent")
    alias_form_component = Module.concat(["#{parsed_opts.module_name}FormComponent"])

    quote do
      defmodule unquote(index_module) do
        @moduledoc false

        use unquote(modules.web), :live_view

        import AuroraUixWeb.Template, only: [compile_heex: 3]

        alias unquote(modules.context)
        alias unquote(modules.module)
        alias unquote(form_component), as: unquote(alias_form_component)

        @impl true
        def render(assigns) do
          # Ensure `assigns` is in scope for Phoenix's HEEx engine, macro hygienic won't pass assigns from caller.
          var!(assigns) = assigns
          compile_heex(unquote(modules.module), unquote(type), unquote(parsed_opts))
        end

        @impl true
        def mount(_params, _session, socket) do
          {:ok,
           stream(
             socket,
             unquote(list_key),
             apply(unquote(modules.context), unquote(list_function), [])
           )}
        end

        @impl true
        def handle_params(params, _url, socket) do
          {:noreply, apply_action(socket, socket.assigns.live_action, params)}
        end

        @impl true
        def handle_event("delete", %{"id" => id}, socket) do
          instance = apply(unquote(modules.context), unquote(get_function), [id])

          {:ok, _} = apply(unquote(modules.context), unquote(delete_function), [instance])

          {:noreply, stream_delete(socket, unquote(list_key), instance)}
        end

        @impl true
        def handle_info({_component, {:saved, entity}}, socket) do
          {:noreply, stream_insert(socket, unquote(list_key), entity)}
        end

        ## PRIVATE

        @spec apply_action(Phoenix.LiveView.Socket.t(), atom, map) :: Phoenix.LiveView.t()
        defp apply_action(socket, :edit, %{"id" => id}) do
          socket
          |> assign(:page_title, "Edit #{unquote(parsed_opts.name)}")
          |> assign(
            :_entity,
            apply(unquote(modules.context), unquote(get_function), [id])
          )
        end

        defp apply_action(socket, :new, _params) do
          socket
          |> assign(:page_title, "New #{unquote(parsed_opts.name)}")
          |> assign(:_entity, %unquote(modules.module){})
        end

        defp apply_action(socket, :index, _params) do
          socket
          |> assign(:page_title, "Listing #{unquote(parsed_opts.title)}")
          |> assign(:_entity, nil)
        end
      end
    end
  end

  def generate_module(modules, :show = type, parsed_opts) do
    get_function = String.to_atom("get_#{parsed_opts.module}!")
    show_module = module_name(modules, parsed_opts, ".Show")
    form_component = module_name(modules, parsed_opts, ".FormComponent")
    alias_form_component = Module.concat(["#{parsed_opts.module_name}FormComponent"])

    quote do
      defmodule unquote(show_module) do
        @moduledoc false

        use unquote(modules.web), :live_view

        import AuroraUixWeb.Template, only: [compile_heex: 3]

        alias unquote(modules.context)
        alias unquote(modules.module)
        alias unquote(form_component), as: unquote(alias_form_component)

        @impl true
        def mount(_params, _session, socket) do
          {:ok, socket}
        end

        @impl true
        def render(assigns) do
          # Ensure `assigns` is in scope for Phoenix's HEEx engine, macro hygienic won't pass assigns from caller.
          var!(assigns) = assigns
          compile_heex(unquote(modules.module), unquote(type), unquote(parsed_opts))
        end

        @impl true
        def handle_params(%{"id" => id}, _, socket) do
          {:noreply,
           socket
           |> assign(
             :page_title,
             page_title(socket.assigns.live_action, unquote(parsed_opts.name))
           )
           |> assign(:subtitle, " Detail")
           |> assign_new(:_auix_sections, fn -> %{} end)
           |> assign(:_entity, apply(unquote(modules.context), unquote(get_function), [id]))}
        end

        @impl true
        def handle_event("switch_section", %{"tab-id" => sections_tab_id}, socket) do
          %{"sections_id" => sections_id, "tab_id" => tab_id} = Jason.decode!(sections_tab_id)

          {:noreply,
           assign(
             socket,
             :_auix_sections,
             Map.put(socket.assigns._auix_sections, sections_id, tab_id)
           )}
        end

        defp page_title(action, suffix) do
          action
          |> to_string()
          |> String.capitalize()
          |> Kernel.<>(" #{suffix}")
        end
      end
    end
  end

  def generate_module(modules, :form = type, parsed_opts) do
    parsed_opts = remove_omitted_fields(parsed_opts)

    change_function = String.to_atom("change_#{parsed_opts.module}")
    update_function = String.to_atom("update_#{parsed_opts.module}")
    create_function = String.to_atom("create_#{parsed_opts.module}")
    form_component = module_name(modules, parsed_opts, ".FormComponent")

    quote do
      defmodule unquote(form_component) do
        @moduledoc false

        use unquote(modules.web), :live_component

        import AuroraUixWeb.Template, only: [compile_heex: 3]

        alias unquote(modules.context)

        @impl true
        def render(assigns) do
          # Ensure `assigns` is in scope for Phoenix's HEEx engine, macro hygienic won't pass assigns from caller.
          var!(assigns) = assigns
          compile_heex(unquote(modules.module), unquote(type), unquote(parsed_opts))
        end

        @impl true
        def update(%{:entity => entity} = assigns, socket) do
          form =
            unquote(modules.context)
            |> apply(unquote(change_function), [entity])
            |> to_form()

          {:ok,
           socket
           |> assign(assigns)
           |> assign_new(:form, fn -> form end)
           |> assign_new(:_auix_sections, fn -> %{} end)}
        end

        @impl true
        def handle_event("validate", %{unquote(parsed_opts.module) => entity_params}, socket) do
          changeset =
            apply(unquote(modules.context), unquote(change_function), [
              socket.assigns[:entity],
              entity_params
            ])

          {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
        end

        def handle_event("save", %{unquote(parsed_opts.module) => entity_params}, socket) do
          save_entity(socket, socket.assigns.action, entity_params)
        end

        @impl true
        @impl true
        def handle_event("switch_section", %{"tab-id" => sections_tab_id}, socket) do
          %{"sections_id" => sections_id, "tab_id" => tab_id} = Jason.decode!(sections_tab_id)

          {:noreply,
           assign(
             socket,
             :_auix_sections,
             Map.put(socket.assigns._auix_sections, sections_id, tab_id)
           )}
        end

        defp save_entity(socket, :edit, entity_params) do
          case apply(unquote(modules.context), unquote(update_function), [
                 socket.assigns[:entity],
                 entity_params
               ]) do
            {:ok, entity} ->
              notify_parent({:saved, entity})

              {:noreply,
               socket
               |> put_flash(:info, "#{unquote(parsed_opts.name)} updated successfully")
               |> push_patch(to: socket.assigns.patch)}

            {:error, %Ecto.Changeset{} = changeset} ->
              {:noreply, assign(socket, form: to_form(changeset))}
          end
        end

        defp save_entity(socket, :new, entity_params) do
          case apply(unquote(modules.context), unquote(create_function), [entity_params]) do
            {:ok, entity} ->
              notify_parent({:saved, entity})

              {:noreply,
               socket
               |> put_flash(:info, "#{unquote(parsed_opts.name)} created successfully")
               |> push_patch(to: socket.assigns.patch)}

            {:error, %Ecto.Changeset{} = changeset} ->
              {:noreply, assign(socket, form: to_form(changeset))}
          end
        end

        defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
      end
    end
  end

  def generate_module(_modules, _type, _parsed_opts) do
    quote do
      # no generation
    end
  end

  ## private

  @spec module_name(map, map, binary) :: module
  defp module_name(modules, parsed_opts, suffix) do
    Module.concat(modules.caller, "#{parsed_opts.module_name}#{suffix}")
  end

  @spec remove_omitted_fields(map) :: map
  defp remove_omitted_fields(parsed_options) do
    parsed_options
    |> Map.get(:fields, %{})
    |> Enum.reject(& &1.omitted)
    |> then(&Map.put(parsed_options, :fields, &1))
  end
end
