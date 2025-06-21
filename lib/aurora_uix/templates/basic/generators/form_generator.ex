defmodule Aurora.Uix.Web.Templates.Basic.Generators.FormGenerator do
  @moduledoc """
  Generates form component modules for the Basic template implementation.

  Provides functionality for:
  - Form validation and submission
  - Entity creation and updates
  - Dynamic section switching
  - Parent component notifications
  """

  import Aurora.Uix.Web.Templates.Basic.ModulesGenerator,
    only: [module_name: 3, remove_omitted_fields: 1]

  alias Aurora.Uix.Web.Templates.Basic.Helpers

  @doc """
  Generates a LiveComponent module for form handling.

  ## Parameters
    - modules (map()) - Map containing web, context modules and component references
    - parsed_opts (map()) - Form configuration with tag: :form and function references

  Returns:
    - Macro.t() - Generated form component module
  """
  @spec generate_module(map(), map()) :: Macro.t()
  def generate_module(modules, %{_path: %{tag: :form}} = parsed_opts) do
    parsed_opts = remove_omitted_fields(parsed_opts)

    change_function = parsed_opts.change_function
    create_function = parsed_opts.create_function
    get_function = parsed_opts.get_function
    update_function = parsed_opts.update_function
    form_component = module_name(modules, parsed_opts, ".FormComponent")
    core_helpers = Aurora.Uix.Web.Templates.Basic.Helpers

    one2many_preload =
      parsed_opts
      |> Helpers.extract_association_preload()
      |> Map.get(:one_to_many_association, [])

    one2many_rendered? =
      parsed_opts
      |> Map.get(:_path)
      |> Helpers.flat_paths()
      |> Enum.filter(&(&1.tag == :field and &1.name in one2many_preload))
      |> Enum.empty?()
      |> Kernel.not()

    quote do
      defmodule unquote(form_component) do
        @moduledoc false

        use unquote(modules.web), :live_component

        import unquote(core_helpers)

        alias Aurora.Uix.Layout.Helpers, as: LayoutHelpers
        alias Aurora.Uix.Stack
        alias Aurora.Uix.Web.Templates.Basic.Renderer
        alias unquote(modules.context)

        @impl true
        def update(%{:auix_entity => entity} = assigns, socket) do
          LayoutHelpers.start_counter(:auix_fields)

          form =
            unquote(modules.context)
            |> apply(unquote(change_function), [entity])
            |> to_form()

          {:ok,
           socket
           |> assign(assigns)
           |> assign_parsed_opts(unquote(Macro.escape(parsed_opts)))
           |> assign_auix_new(:_form, form)
           |> assign_auix_new(:_sections, %{})
           |> assign_auix(:_myself, socket.assigns.myself)
           |> assign_auix(
             :_routing_stack,
             Map.get(assigns, :auix_routing_stack, Stack.new())
           )
           |> render_with(&Renderer.render/1)}
        end

        @impl true
        def handle_event("validate", %{unquote(parsed_opts.module) => entity_params}, socket) do
          socket = Phoenix.LiveView.clear_flash(socket)

          changeset =
            apply(unquote(modules.context), unquote(change_function), [
              socket.assigns[:auix_entity],
              entity_params
            ])

          {:noreply, assign_auix(socket, :_form, to_form(changeset, action: :validate))}
        end

        def handle_event("save", %{unquote(parsed_opts.module) => entity_params}, socket) do
          socket
          |> Phoenix.LiveView.clear_flash()
          |> save(entity_params)
        end

        @impl true
        def handle_event("switch_section", %{"tab-id" => sections_tab_id}, socket) do
          %{"sections_id" => sections_id, "tab_id" => tab_id} = Jason.decode!(sections_tab_id)

          socket = Phoenix.LiveView.clear_flash(socket)

          {:noreply, assign_auix_sections(socket, sections_id, tab_id)}
        end

        def handle_event("auix_route_back", _params, socket) do
          {:noreply, auix_route_back(socket)}
        end

        def handle_event(event, params, socket) do
          raise "Event not handled. event: #{inspect(event)}. params: #{inspect(params)}"
        end

        # Handles entity saving process and updates the UI accordingly
        defp save(%{assigns: %{action: action}} = socket, entity_params) do
          case save_entity(socket, action, entity_params) do
            {:ok, entity} ->
              notify_parent({:saved, entity})

              new_entity =
                apply(unquote(modules.context), unquote(get_function), [
                  entity.id,
                  [preload: unquote(Macro.escape(parsed_opts.preload))]
                ])

              {:noreply,
               socket
               |> put_flash(:info, "#{unquote(parsed_opts.name)} updated successfully")
               |> assign(:auix_entity, new_entity)
               |> assign(:action, :edit)
               |> conditional_route_back(action, unquote(one2many_rendered?))}

            {:error, %Ecto.Changeset{} = changeset} ->
              {:noreply,
               socket
               |> put_flash(:error, format_changeset_errors(changeset))
               |> assign_auix(:_form, to_form(changeset))}
          end
        end

        # Persists entity changes using the appropriate context function
        defp save_entity(socket, :edit, entity_params) do
          apply(unquote(modules.context), unquote(update_function), [
            socket.assigns[:auix_entity],
            entity_params
          ])
        end

        defp save_entity(socket, :new, entity_params) do
          apply(unquote(modules.context), unquote(create_function), [entity_params])
        end

        defp conditional_route_back(
               %{assigns: %{_auix: %{_routing_stack: routing_stack}, auix_entity: entity}} =
                 socket,
               :new,
               true
             ) do
          {new_routing_stack, original_path} = Stack.pop!(routing_stack)

          original_path
          |> Map.get(:path)
          |> URI.parse()
          |> Map.get(:path)
          |> then(&"#{&1}/#{Map.get(entity, :id)}/edit")
          |> then(
            &assign_auix(
              socket,
              :_routing_stack,
              Stack.push(new_routing_stack, %{type: :navigate, path: &1})
            )
          )
          |> auix_route_back()
        end

        defp conditional_route_back(socket, _action, _one2many_rendered?),
          do: auix_route_back(socket)

        # Sends a message to the parent LiveView with the operation result
        defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
      end
    end
  end
end
