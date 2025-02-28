defmodule AuroraUixWeb.Templates.Base do
  @moduledoc """
  A module for generating basic HEEx templates for different UI component types.

  This module provides a single function, `generate_view/2`,
  which creates HEEx template fragments based on the specified type.
  Currently, it supports the following types:

  - `:live_view`: Generates a template for a list.
  - `:card`: Generates a template for a card.
  - `:form`: Generates a template for a form.

  ## Examples

  ```elixir
  iex> AuroraUixWeb.Templates.Base.generate_view(:index, %{})
  # => "<h1>Base Template</h1>list"

  iex> AuroraUixWeb.Templates.Base.generate_view(:card, %{})
  # => "<h1>Base Template</h1>card"

  iex> AuroraUixWeb.Templates.Base.generate_view(:form, %{})
  # => "<h1>Base Template</h1>form"
  ```
  """

  @behaviour AuroraUixWeb.Template

  alias AuroraUixWeb.Template

  @doc """
  Generates a basic HEEx template fragment for the specified type.

  ## Parameters

  - `type` (atom): Specifies the type of template to generate.
    Supported values: `:index`, `:card`, `:form`.

  - `parsed_opts` (map): A map of options (currently unused in this implementation).

  ## Returns

  - `binary`: A HEEx template corresponding to the specified type.

  ## Examples

  ```elixir
  generate(:index, %{})
  # => "<h1>Base Template</h1>list"

  generate(:card, %{})
  # => "<h1>Base Template</h1>card"

  generate(:form, %{})
  # => "<h1>Base Template</h1>form"
  ```
  """
  @spec generate_view(atom, map) :: binary
  def generate_view(:index, parsed_opts) do
    parsed_opts =
      parsed_opts
      |> remove_disabled_fields()
      |> columns()
      |> then(&Map.put(parsed_opts, :columns, &1))

    Template.build(
      parsed_opts,
      ~S"""
        <.header>
          Listing [[title]]
          <:actions>
            <.link patch={~p"/[[link]]/new"} id="auix-new-[[source]]">
              <.button>New [[title]]</.button>
            </.link>
          </:actions>
        </.header>

        <.table
            id={"auix-list-[[link]]"}
            rows={get_in(assigns, @_uix.rows)}
            row_click={fn {_id, row} -> JS.navigate(~p"/[[link]]/#{row}") end}
        >
          [[columns]]
          <:action :let={{id, [[module]]}}>
            <div class="sr-only">
              <.link navigate={~p"/[[link]]/#{[[module]]}"} id={"auix-show-#{id}"}>Show</.link>
            </div>
            <.link patch={~p"/[[link]]/#{[[module]]}/edit"} id={"auix-edit-#{id}"}>Edit</.link>
          </:action>
          <:action :let={{id, _[[module]]}}>
            <.link
              phx-click={JS.push("delete", value: %{id: id}) |> hide("##{id}")}
              data-confirm="Are you sure?"
              id={"auix-delete-#{id}"}
            >
              Delete
            </.link>
          </:action>
        </.table>

        <.modal :if={@live_action in [:new, :edit]} id="auix-[[module]]-modal" show on_cancel={JS.patch(~p"/[[link]]")}>
          <.live_component
            module={[[module_name]]FormComponent}
            id={@_entity.id || :new}
            title={@page_title}
            action={@live_action}
            entity={@_entity}
            patch={~p"/[[link]]"}
          />
        </.modal>
      """
    )
  end

  def generate_view(:show, parsed_opts) do
    parsed_opts =
      parsed_opts
      |> remove_disabled_fields()
      |> field_list()
      |> then(&Map.put(parsed_opts, :field_list, &1))

    Template.build(
      parsed_opts,
      ~S"""
      <.header>
        [[name]] {@_entity.id}
        <:subtitle>[[subtitle]]</:subtitle>
        <:actions>
          <.link patch={~p"/[[link]]/#{@_entity}/show/edit"} phx-click={JS.push_focus()} id="auix-edit-[[source]]">
            <.button>Edit [[name]]</.button>
          </.link>
        </:actions>
      </.header>

      <.list>
        [[field_list]]
      </.list>

      <.back navigate={~p"/[[link]]"}>Back to [[name]]</.back>

      <.modal :if={@live_action == :edit}
        id="auix-[[module]]-modal"
        show
        on_cancel={JS.patch(~p"/[[link]]/#{@_entity}")}
      >
        <.live_component
          module={[[module_name]]FormComponent}
          id={@_entity.id}
          title={@page_title}
          action={@live_action}
          entity={@_entity}
          patch={~p"/[[link]]/#{@_entity}"}
        />
      </.modal>
      """
    )
  end

  def generate_view(:form, parsed_opts) do
    parsed_opts =
      parsed_opts
      |> remove_disabled_fields()
      |> form_fields()
      |> then(&Map.put(parsed_opts, :form_fields, &1))

    Template.build(
      parsed_opts,
      ~S"""
        <div>
          <.header>
            {@title}
            <:subtitle>Use this form to manage [[module]] records in your database.</:subtitle>
          </.header>

          <.simple_form
            for={@form}
            id="auix-[[module]]-form"
            phx-target={@myself}
            phx-change="validate"
            phx-submit="save"
          >
            [[form_fields]]
            <:actions>
              <.button phx-disable-with="Saving..." id="auix-save-[[source]]">Save [[name]]</.button>
            </:actions>
          </.simple_form>
        </div>
      """
    )
  end

  def generate_view(:card, _parsed_opts) do
    ~S"""
      <h1>Base Template</h1>
    card
    """
  end

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

  The function expects the provided context and module to define the following functions:

  - `list_<source>()` - Returns a list of all entities for streaming.
  - `get_<schema_module>!(id)` - Fetches a specific entity by its ID.
  - `delete_<schema_module>(instance)` - Deletes a specific entity.

  ## Notes

  - The generated module provides standard LiveView functionality, including dynamic assignment
  of page titles and CRUD operations for the specified schema or context module.
  """
  @spec generate_module(map, atom, map) :: Macro.t()
  def generate_module(modules, :index = type, parsed_opts) do
    parsed_opts = remove_disabled_fields(parsed_opts)

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
        import AuroraUixWeb.Uix.Renderer

        alias unquote(modules.context)
        alias unquote(modules.module)
        alias unquote(form_component), as: unquote(alias_form_component)

        @impl true
        def render(assigns) do
          # Ensure `assigns` is in scope for Phoenix's HEEx engine, macro hygienic won't pass assigns from caller.
          var!(assigns) = assigns
          define(unquote(modules.module), unquote(type), unquote(parsed_opts))
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
        import AuroraUixWeb.Uix.Renderer

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
          define(unquote(modules.module), unquote(type), unquote(parsed_opts))
        end

        @impl true
        def handle_params(%{"id" => id}, _, socket) do
          {:noreply,
           socket
           |> assign(
             :page_title,
             page_title(socket.assigns.live_action, unquote(parsed_opts.name))
           )
           |> assign(:_entity, apply(unquote(modules.context), unquote(get_function), [id]))}
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
    parsed_opts = remove_disabled_fields(parsed_opts)

    change_function = String.to_atom("change_#{parsed_opts.module}")
    update_function = String.to_atom("update_#{parsed_opts.module}")
    create_function = String.to_atom("create_#{parsed_opts.module}")
    form_component = module_name(modules, parsed_opts, ".FormComponent")

    quote do
      defmodule unquote(form_component) do
        @moduledoc false

        use unquote(modules.web), :live_component
        import AuroraUixWeb.Uix.Renderer

        alias unquote(modules.context)

        @impl true
        def render(assigns) do
          # Ensure `assigns` is in scope for Phoenix's HEEx engine, macro hygienic won't pass assigns from caller.
          var!(assigns) = assigns
          define(unquote(modules.module), unquote(type), unquote(parsed_opts))
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
           |> assign_new(:form, fn -> form end)}
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

  ## PRIVATE

  @spec columns(map) :: binary
  defp columns(%{fields: fields}) do
    # <:col :let={{_id, account}} label="Number">{account.number}</:col>
    Enum.map_join(fields, "\n", fn field ->
      "<:col :let={{_id, entity}} label=\"#{field.label}\">{entity.#{field.name}}</:col>"
    end)
  end

  @spec field_list(map) :: binary
  defp field_list(%{fields: fields}) do
    # <:item title="Number">{@account.number}</:item>
    Enum.map_join(fields, "\n", fn field ->
      "<:item title=\"#{field.label}\">{@_entity.#{field.name}}</:item>"
    end)
  end

  @spec form_fields(map) :: binary
  defp form_fields(%{fields: fields, module: module}) do
    # <.input field={@form[:number]} type="text" label="Number" />
    Enum.map_join(
      fields,
      "\n",
      fn
        %{hidden: true} = field ->
          """
            <.input
              field={@form[:#{field.field}]}
              type="#{field.html_type}"
              label="hidden #{field.label}"
              id="auix-field-#{module}_#{field.field}"/>
          """

        field ->
          """
            <.input
              field={@form[:#{field.field}]}
              type="#{field.html_type}"
              label="#{field.label}"
              id="auix-field-#{module}_#{field.field}"/>
          """
      end
    )
  end

  @spec module_name(map, map, binary) :: module
  defp module_name(modules, parsed_opts, suffix) do
    Module.concat(modules.caller, "#{parsed_opts.module_name}#{suffix}")
  end

  @spec remove_disabled_fields(map) :: map
  defp remove_disabled_fields(parsed_options) do
    parsed_options
    |> Map.get(:fields, %{})
    |> Enum.reject(& &1.disabled)
    |> then(&Map.put(parsed_options, :fields, &1))
  end
end
