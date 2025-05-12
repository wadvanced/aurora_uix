defmodule Aurora.Uix.Web.Templates.Core.LogicModulesGenerator do
  @moduledoc """
  Dynamic LiveView module generator for creating CRUD-oriented user interfaces.

  ## Module Generation Capabilities
  Automatically generates complete LiveView modules with:
  - Comprehensive CRUD operations
  - Dynamic event handling
  - Integrated form validation
  - Flexible rendering strategies

  ## Generation Strategies
  Supports multiple UI component types:
  - `:index`: Streamed entity listings with pagination and filtering
  - `:show`: Detailed entity views with section navigation
  - `:form`: Interactive data entry and editing with validation
  - `:aurora_index_list`: Specialized listing component with advanced features

  ## Key Generation Features
  - Automatic socket management and streaming
  - Built-in event handlers for CRUD operations
  - Context-aware database operations
  - Metadata-driven module creation
  - Section navigation support

  ## Generation Workflow
  1. Analyze provided modules and context
  2. Dynamically create LiveView/LiveComponent modules
  3. Implement standard CRUD lifecycle methods
  4. Generate type-specific rendering logic

  ## Context Requirements
  Generated modules expect context modules to provide:
  - `list_<source>/0`: Retrieve entity collections
  - `get_<schema>!/1`: Fetch specific entities
  - `change_<schema>/1-2`: Validate entity changes
  - `create_<schema>/1`: Create new entities
  - `update_<schema>/2`: Update existing entities
  - `delete_<schema>/1`: Remove existing entities

  ## Design Principles
  - Minimize boilerplate code
  - Maintain consistent UI interaction patterns
  - Support extensible module generation
  - Provide type-safe implementations

  ## Usage Example
  ```elixir
    generate_module(
    %{
      caller: MyAppWeb,
      context: MyApp.Accounts,
      module: MyApp.User,
      web: MyAppWeb
    },
    :index,
    %{source: "users", module: "User"}
    )
  ```
  Transforms configuration into fully-functional, dynamically generated LiveView modules.
  """

  require Logger

  @doc """
  Dynamically generates a LiveView module for specified UI component type.

  ## Parameters
  - `modules` (map): Configuration for module generation
    - `caller`: The calling module
    - `context`: Context module for data operations
    - `module`: Schema/resource module
    - `web`: Web module for LiveView integration

  - `type` (atom): UI component type (:index, :show, :form, :aurora_index_list)
  - `parsed_opts` (map): Detailed generation options
    - `source`: The data source name (e.g. "users")
    - `module`: The module name (e.g. "User")
    - `name`: Singular name for entity
    - `title`: Title for plural display
    - Optional function overrides:
      - `list_function`: Function to list all entities
      - `get_function`: Function to retrieve one entity
      - `delete_function`: Function to delete an entity
      - `change_function`: Function to create a changeset
      - `update_function`: Function for updating entities
      - `create_function`: Function for creating entities

  ## Returns
  A quoted Elixir module definition ready for compilation

  ## Supported Types
  - `:index`: Generates a listing LiveView with CRUD capabilities
  - `:show`: Generates a detail view LiveView with section navigation
  - `:form`: Generates a form LiveComponent with validation
  - `:aurora_index_list`: Generates a specialized listing component

  ## Example
  ```elixir
    generate_module(
      %{caller: UserWeb, context: Users, module: User, web: Web},
      :index,
      %{source: "users", title: "User Management"}
    )
  ```
  ## Generated Behaviour

  The function expects the provided context and module to have the following functions defined:

  - `list_<source>/0`: Returns a list of all entities for streaming
  - `get_<schema_module>!/1`: Fetches a specific entity by its ID
  - `delete_<schema_module>/1`: Deletes a specific entity
  - `change_<schema_module>/1-2`: Creates a changeset for validation
  - `update_<schema_module>/2`: Updates an existing entity with new attributes
  - `create_<schema_module>/1`: Creates a new entity with provided attributes

  ## Notes

  The generated module provides standard LiveView functionality, including dynamic assignment
  of page titles, CRUD operations, and section navigation for multi-part forms or detail views.
  """
  @spec generate_module(map, atom, map) :: Macro.t()
  def generate_module(modules, :index = type, parsed_opts) do
    parsed_opts = remove_omitted_fields(parsed_opts)

    list_key = String.to_existing_atom(parsed_opts.source)
    list_function = parsed_opts.list_function
    get_function = parsed_opts.get_function
    delete_function = parsed_opts.delete_function
    new_function = parsed_opts.new_function
    index_module = module_name(modules, parsed_opts, ".Index")
    form_component = module_name(modules, parsed_opts, ".FormComponent")
    alias_form_component = Module.concat(["#{parsed_opts.module_name}FormComponent"])
    core_helpers = Aurora.Uix.Web.Templates.Core.Helpers

    quote do
      defmodule unquote(index_module) do
        @moduledoc false

        use unquote(modules.web), :live_view

        import unquote(core_helpers)
        import Aurora.Uix.Web.Template, only: [compile_heex: 2]

        alias unquote(modules.context)
        alias unquote(modules.module)
        alias unquote(form_component), as: unquote(alias_form_component)

        @impl true
        def render(assigns) do
          # Ensure `assigns` is in scope for Phoenix's HEEx engine, macro hygienic won't pass assigns from caller.
          var!(assigns) = assigns
          compile_heex(unquote(type), unquote(parsed_opts))
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
          {:noreply,
           socket
           |> assign_index_row_click(params, unquote(Macro.escape(parsed_opts)))
           |> apply_action(socket.assigns.live_action, params)}
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
        defp apply_action(socket, :edit, %{"id" => id} = params) do
          socket
          |> assign(:page_title, "Edit #{unquote(parsed_opts.name)}")
          |> assign_source(params, unquote(parsed_opts.source))
          |> assign(
            :auix_entity,
            apply(unquote(modules.context), unquote(get_function), [
              id,
              [preload: unquote(Macro.escape(parsed_opts.preload))]
            ])
          )
        end

        defp apply_action(socket, :new, params) do
          socket
          |> assign(:page_title, "New #{unquote(parsed_opts.name)}")
          |> assign_source(params, unquote(parsed_opts.source))
          |> assign_new_entity(
            params,
            apply(unquote(modules.context), unquote(new_function), [
              [preload: unquote(Macro.escape(parsed_opts.preload))]
            ])
          )
        end

        defp apply_action(socket, :index, _params) do
          socket
          |> assign(:page_title, "Listing #{unquote(parsed_opts.title)}")
          |> assign(:auix_entity, nil)
        end
      end
    end
  end

  def generate_module(modules, :show = type, parsed_opts) do
    get_function = parsed_opts.get_function
    show_module = module_name(modules, parsed_opts, ".Show")
    form_component = module_name(modules, parsed_opts, ".FormComponent")
    alias_form_component = Module.concat(["#{parsed_opts.module_name}FormComponent"])
    components = Aurora.Uix.Web.Components.AuroraCoreComponents
    core_helpers = Aurora.Uix.Web.Templates.Core.Helpers

    quote do
      defmodule unquote(show_module) do
        @moduledoc false

        use unquote(modules.web), :live_view

        import unquote(core_helpers)
        import Aurora.Uix.Web.Template, only: [compile_heex: 2]

        alias unquote(modules.context)
        alias unquote(modules.module)
        alias unquote(form_component), as: unquote(alias_form_component)
        alias unquote(components)

        @impl true
        def mount(_params, _session, socket) do
          {:ok, socket}
        end

        @impl true
        def render(assigns) do
          # Ensure `assigns` is in scope for Phoenix's HEEx engine, macro hygienic won't pass assigns from caller.
          var!(assigns) = assigns
          compile_heex(unquote(type), unquote(parsed_opts))
        end

        @impl true
        def handle_params(%{"id" => id} = params, _, socket) do
          {:noreply,
           socket
           |> assign(
             :page_title,
             page_title(socket.assigns.live_action, unquote(parsed_opts.name))
           )
           |> assign(:subtitle, " Detail")
           |> assign_new(:_auix_sections, fn -> %{} end)
           |> assign_source(params, unquote(parsed_opts.source))
           |> assign(
             :auix_entity,
             apply(unquote(modules.context), unquote(get_function), [
               id,
               [preload: unquote(Macro.escape(parsed_opts.preload))]
             ])
           )}
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

    change_function = parsed_opts.change_function
    update_function = parsed_opts.update_function
    create_function = parsed_opts.create_function
    form_component = module_name(modules, parsed_opts, ".FormComponent")
    core_helpers = Aurora.Uix.Web.Templates.Core.Helpers

    quote do
      defmodule unquote(form_component) do
        @moduledoc false

        use unquote(modules.web), :live_component

        import unquote(core_helpers)
        import Aurora.Uix.Web.Template, only: [compile_heex: 2]

        alias unquote(modules.context)

        @impl true
        def render(assigns) do
          # Ensure `assigns` is in scope for Phoenix's HEEx engine, macro hygienic won't pass assigns from caller.
          var!(assigns) = assigns
          compile_heex(unquote(type), unquote(parsed_opts))
        end

        @impl true
        def update(%{:auix_entity => entity} = assigns, socket) do
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
          socket = Phoenix.LiveView.clear_flash(socket)

          changeset =
            apply(unquote(modules.context), unquote(change_function), [
              socket.assigns[:auix_entity],
              entity_params
            ])

          {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
        end

        def handle_event("save", %{unquote(parsed_opts.module) => entity_params}, socket) do
          socket = Phoenix.LiveView.clear_flash(socket)
          save(socket, socket.assigns.action, entity_params)
        end

        @impl true
        def handle_event("switch_section", %{"tab-id" => sections_tab_id}, socket) do
          %{"sections_id" => sections_id, "tab_id" => tab_id} = Jason.decode!(sections_tab_id)

          socket = Phoenix.LiveView.clear_flash(socket)

          {:noreply,
           assign(
             socket,
             :_auix_sections,
             Map.put(socket.assigns._auix_sections, sections_id, tab_id)
           )}
        end

        defp save(socket, action, entity_params) do
          case save_entity(socket, action, entity_params) do
            {:ok, entity} ->
              notify_parent({:saved, entity})

              {:noreply,
               socket
               |> put_flash(:info, "#{unquote(parsed_opts.name)} updated successfully")
               |> push_navigate(to: socket.assigns.patch)}

            {:error, %Ecto.Changeset{} = changeset} ->
              {:noreply, assign(socket, form: to_form(changeset))}
          end
        end

        defp save_entity(socket, :edit, entity_params) do
          apply(unquote(modules.context), unquote(update_function), [
            socket.assigns[:auix_entity],
            entity_params
          ])
        end

        defp save_entity(socket, :new, entity_params) do
          apply(unquote(modules.context), unquote(create_function), [entity_params])
        end

        defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
      end
    end
  end

  def generate_module(_modules, type, _parsed_opts) do
    Logger.error("The logic for `#{inspect(type)} is not implemented.")

    quote do
      # no generation
    end
  end

  @doc """
  Removes omitted fields from the parsed options.

  Filters out fields marked with `omitted: true` to exclude them from
  form rendering and validation processing.

  ## Parameters
  - `parsed_options` (map): The options map containing field definitions

  ## Returns
  Updated map with omitted fields removed

  ## Example
  ```elixir
    remove_omitted_fields(%{fields: [%{name: "email"}, %{name: "deleted_at", omitted: true}]})
    # Returns: %{fields: [%{name: "email"}]}
  ```
  """
  @spec remove_omitted_fields(map) :: map
  def remove_omitted_fields(parsed_options) do
    parsed_options
    |> Map.get(:fields, %{})
    |> Enum.reject(& &1.omitted)
    |> then(&Map.put(parsed_options, :fields, &1))
  end

  ## private

  @spec module_name(map, map, binary) :: module
  defp module_name(modules, parsed_opts, suffix) do
    Module.concat(modules.caller, "#{parsed_opts.module_name}#{suffix}")
  end
end
