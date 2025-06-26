defmodule Aurora.Uix.Web.Templates.Basic.Generators.ShowGenerator do
  @moduledoc """
  Provides a macro to generate LiveView modules for detail (show) pages in Aurora UIX Basic templates.

  ## Key Features

  - Generates LiveView modules for detail (show) views
  - Supports dynamic section switching
  - Displays entity data with preload support
  - Integrates with form components
  - Integrates with Aurora UIX context and helpers
  """

  import Aurora.Uix.Web.Templates.Basic.ModulesGenerator,
    only: [module_name: 3, remove_omitted_fields: 1]

  @doc """
  Generates a show view LiveView module with detail display and section handling.

  ## Parameters
  - `modules` (map()) – Map containing web, context modules, and component references
  - `parsed_opts` (map()) – Show view configuration with `tag: :show`

  ## Returns
  - `Macro.t()` – The generated show view module as quoted code.

  """
  @spec generate_module(map(), map()) :: Macro.t()
  def generate_module(modules, %{_path: %{tag: :show}} = parsed_opts) do
    parsed_opts = remove_omitted_fields(parsed_opts)

    get_function = parsed_opts.get_function
    show_module = module_name(modules, parsed_opts, ".Show")
    form_component = module_name(modules, parsed_opts, ".FormComponent")
    alias_form_component = Module.concat(["#{parsed_opts.module_name}FormComponent"])
    components = Aurora.Uix.Web.Components.AuroraCoreComponents
    core_helpers = Aurora.Uix.Web.Templates.Basic.Helpers

    quote do
      defmodule unquote(show_module) do
        @moduledoc false

        use unquote(modules.web), :live_view

        import unquote(core_helpers)

        alias Aurora.Uix.Web.Templates.Basic.Renderer
        alias unquote(modules.context)
        alias unquote(modules.module)
        alias unquote(form_component), as: unquote(alias_form_component)
        alias unquote(components)

        @impl true
        def mount(_params, _session, socket) do
          {:ok, socket}
        end

        @impl true
        def handle_params(%{"id" => id} = params, url, socket) do
          {:noreply,
           socket
           |> assign(
             :page_title,
             page_title(socket.assigns.live_action, unquote(parsed_opts.name))
           )
           |> assign(:subtitle, " Detail")
           |> assign_parsed_opts(unquote(Macro.escape(parsed_opts)))
           |> assign_auix_new(:_sections, %{})
           |> assign(
             :auix_entity,
             apply(unquote(modules.context), unquote(get_function), [
               id,
               [preload: unquote(Macro.escape(parsed_opts.preload))]
             ])
           )
           |> assign_auix(:_form_component, unquote(form_component))
           |> assign_auix_current_path(url)
           |> assign_auix_routing_stack(params, %{
             type: :navigate,
             path: "/#{unquote(parsed_opts.link_prefix)}#{unquote(parsed_opts.source)}"
           })
           |> render_with(&Renderer.render/1)}
        end

        @impl true
        def handle_event("switch_section", %{"tab-id" => sections_tab_id}, socket) do
          %{"sections_id" => sections_id, "tab_id" => tab_id} = Jason.decode!(sections_tab_id)

          {:noreply, assign_auix_sections(socket, sections_id, tab_id)}
        end

        def handle_event("delete", params, socket) do
          %{
            "id" => id,
            "context" => context_string,
            "get_function" => get_function_string,
            "delete_function" => delete_function_string
          } = params

          context = String.to_existing_atom(context_string)
          get_function = String.to_existing_atom(get_function_string)
          delete_function = String.to_existing_atom(delete_function_string)

          socket =
            with %{} = entity <- apply(context, get_function, [id]),
                 {:ok, _changeset} <- apply(context, delete_function, [entity]) do
              socket
              |> put_flash(:info, "Item deleted successfully")
              |> push_patch(to: socket.assigns._auix[:_current_path])
            else
              _ -> socket
            end

          {:noreply, socket}
        end

        def handle_event(
              "auix_route_forward",
              %{"route_type" => "navigate", "route_path" => path},
              socket
            ) do
          {:noreply, auix_route_forward(socket, to: path)}
        end

        def handle_event(
              "auix_route_forward",
              %{"route_type" => "patch", "route_path" => path},
              socket
            ) do
          {:noreply, auix_route_forward(socket, patch: path)}
        end

        def handle_event("auix_route_back", _params, socket) do
          {:noreply, auix_route_back(socket)}
        end

        # Formats page title by combining capitalized action with suffix
        defp page_title(action, suffix) do
          action
          |> to_string()
          |> String.capitalize()
          |> Kernel.<>(" #{suffix}")
        end
      end
    end
  end
end
