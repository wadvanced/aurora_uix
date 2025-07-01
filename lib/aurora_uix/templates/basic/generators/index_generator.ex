defmodule Aurora.Uix.Web.Templates.Basic.Generators.IndexGenerator do
  @moduledoc """
  Generates index view LiveView modules for the Basic template implementation.

  This module provides a macro to generate LiveView modules for index (listing) pages in Aurora UIX Basic templates.

  ## Key Features

  - Generates LiveView modules for index (listing) views
  - Supports stream-based data loading
  - Handles CRUD operations (create, read, update, delete)
  - Dynamically mounts components
  - Provides responsive event handling
  - Integrates with Aurora UIX context and helpers

  """

  alias Aurora.Uix.Web.Templates.Basic.ModulesGenerator

  @doc """
  Generates an index view LiveView module with standard CRUD operations in Aurora UIX.

  ## Parameters
  - `modules` (map()) – Map containing web, context, and schema module references
  - `parsed_opts` (map()) – Index view configuration with `tag: :index`

  ## Returns
  - `Macro.t()` – The generated index view module as quoted code

  ## Example

      iex> IndexGenerator.generate_module(%{web: MyAppWeb, context: MyApp.Context, module: MyApp.Entity}, %{_path: %{tag: :index}, source: "entities", ...})
      #=> {:module, ...}
  """
  @spec generate_module(map(), map()) :: Macro.t()
  def generate_module(modules, %{_path: %{tag: :index}} = parsed_opts) do
    parsed_opts = ModulesGenerator.remove_omitted_fields(parsed_opts)

    list_key = String.to_existing_atom(parsed_opts.source)
    list_function = parsed_opts.list_function
    get_function = parsed_opts.get_function
    delete_function = parsed_opts.delete_function
    new_function = parsed_opts.new_function
    index_module = ModulesGenerator.module_name(modules, parsed_opts, ".Index")
    form_component = ModulesGenerator.module_name(modules, parsed_opts, ".FormComponent")
    alias_form_component = Module.concat(["#{parsed_opts.module_name}FormComponent"])
    core_helpers = Aurora.Uix.Web.Templates.Basic.Helpers

    quote do
      defmodule unquote(index_module) do
        @moduledoc false

        use unquote(modules.web), :live_view

        import unquote(core_helpers)

        alias Aurora.Uix.Layout.Helpers, as: LayoutHelpers
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
        def handle_params(params, url, socket) do
          {:noreply,
           socket
           |> assign_parsed_opts(unquote(Macro.escape(parsed_opts)))
           #  |> tap(&MIO.inspect(&1.assigns.auix._configurations, label: "*********** path"))
           |> assign_index_row_click(params)
           |> assign_auix(:_form_component, unquote(form_component))
           |> assign_auix_option(:page_title, "")
           |> assign_auix_option(:page_subtitle, "")
           |> assign_auix_option(:edit_title, "")
           |> assign_auix_option(:edit_subtitle, "")
           |> assign_auix_option(:new_title, "")
           |> assign_auix_option(:new_subtitle, "")
           |> assign_auix_current_path(url)
           |> assign_auix_routing_stack(params, %{
             type: :patch,
             path: "/#{unquote(parsed_opts.link_prefix)}#{unquote(parsed_opts.source)}"
           })
           |> render_with(&Renderer.render/1)
           |> apply_action(socket.assigns.live_action, params)}
        end

        @impl true
        def handle_event(
              "delete",
              %{
                "id" => id,
                "context" => context_name,
                "get_function" => get_function_name,
                "delete_function" => delete_function_name
              },
              socket
            ) do
          context = String.to_existing_atom(context_name)
          get_function = String.to_existing_atom(get_function_name)
          delete_function = String.to_existing_atom(delete_function_name)

          socket =
            with %{} = entity <- apply(context, get_function, [id]),
                 {:ok, _changeset} <- apply(context, delete_function, [entity]) do
              socket
              |> put_flash(:info, "Item deleted successfully")
              |> push_patch(to: socket.assigns.auix[:_current_path])
            else
              _ -> socket
            end

          {:noreply, socket}
        end

        def handle_event("delete", %{"id" => id}, socket) do
          instance = apply(unquote(modules.context), unquote(get_function), [id])

          {:ok, _} = apply(unquote(modules.context), unquote(delete_function), [instance])

          {:noreply, stream_delete(socket, unquote(list_key), instance)}
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

        @impl true
        def handle_info({_component, {:saved, entity}}, socket) do
          {:noreply, stream_insert(socket, unquote(list_key), entity)}
        end

        def handle_info(input, socket) do
          {:noreply, socket}
        end

        ## PRIVATE

        @spec apply_action(Phoenix.LiveView.Socket.t(), atom, map) :: Phoenix.LiveView.t()
        defp apply_action(socket, :edit, %{"id" => id} = params) do
          socket
          |> assign_auix_option(:edit_title)
          |> assign_auix_option(:edit_subtitle)
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
          |> assign_auix_option(:new_title)
          |> assign_auix_option(:new_subtitle)
          |> assign_new_entity(
            params,
            apply(unquote(modules.context), unquote(new_function), [
              %{},
              [preload: unquote(Macro.escape(parsed_opts.preload))]
            ])
          )
        end

        defp apply_action(socket, :index, _params) do
          socket
          |> assign_auix_option(:page_title)
          |> assign_auix_option(:page_subtitle)
          |> assign(:auix_entity, nil)
        end
      end
    end
  end
end
