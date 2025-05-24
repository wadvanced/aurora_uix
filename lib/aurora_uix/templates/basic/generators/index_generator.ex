defmodule Aurora.Uix.Web.Templates.Basic.Generators.IndexGenerator do
  @moduledoc """
  Generator for index view LiveView modules in the Basic template.

  Provides functionality to generate index view modules with:
  - Stream-based data loading
  - CRUD operations handling
  - Dynamic component mounting
  - Responsive event handling
  """

  import Aurora.Uix.Web.Templates.Basic.ModulesGenerator,
    only: [module_name: 3, remove_omitted_fields: 1]

  @doc """
  Generates an index view LiveView module with standard CRUD operations.

  ## Parameters
    - modules (map()) - Map containing web, context, and schema module references
    - parsed_opts (map()) - Index view configuration with tag: :index

  Returns:
    - Macro.t() - Generated module code
  """
  @spec generate_module(map(), map()) :: Macro.t()
  def generate_module(modules, %{_path: %{tag: :index}} = parsed_opts) do
    parsed_opts = remove_omitted_fields(parsed_opts)

    list_key = String.to_existing_atom(parsed_opts.source)
    list_function = parsed_opts.list_function
    get_function = parsed_opts.get_function
    delete_function = parsed_opts.delete_function
    new_function = parsed_opts.new_function
    index_module = module_name(modules, parsed_opts, ".Index")
    form_component = module_name(modules, parsed_opts, ".FormComponent")
    alias_form_component = Module.concat(["#{parsed_opts.module_name}FormComponent"])
    core_helpers = Aurora.Uix.Web.Templates.Basic.Helpers

    quote do
      defmodule unquote(index_module) do
        @moduledoc false

        use unquote(modules.web), :live_view

        import unquote(core_helpers)

        alias Aurora.Uix.Web.Templates.Basic.Renderer
        alias unquote(modules.context)
        alias unquote(modules.module)
        alias unquote(form_component), as: unquote(alias_form_component)

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
           |> assign_parsed_opts(unquote(Macro.escape(parsed_opts)))
           |> assign_index_row_click(params)
           |> assign_auix(:_form_component, unquote(form_component))
           |> render_with(&Renderer.render/1)
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
          |> assign_source(params)
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
          |> assign_source(params)
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
end
