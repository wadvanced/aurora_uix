defmodule AuroraUixWeb.Uix.Renderer do
  @moduledoc """
  Helper module for required macros.
  """

  alias AuroraUixWeb.Template

  require Logger

  @uix_valid_types [:index, :card, :form, :show]

  @doc """
  Defines the generation options for creating a full fledge view.

  ## PARAMETERS
  * `module` (module): Schema module to be used for gathering field information.
  * `type` (atom): Type of view to generate.
    * `:index` : Table like view with selectable fields and action buttons.
    * `:card` : Card like view with configurable card fields.
    * `:form` : Form like view, can have nested elements displayed as block or sections.
  * `opts` (Keyword.t()): List of options, the available ones depends on the type of view.
    ### Common opts
    * `template: Module`: Overrides the module that handles the generation.
      By default uses AuroraUixWeb.AuroraTemplate, which is a sophisticated and highly opinionated template.
      There is also the AuroraUixWeb.PhoenixTemplate, which resembles the phoenix ui.
      The template can also be configured, application wide, by adding :aurora_uix, template: Module.
      New templates can be authored.
    * `field: (AuroraUix.Field)`: Field to be added to the default list or updated.
    * `fields: []`: Fields to be used, overrides the default list.
      The default list is created with all the fields found in the module, excluding
      the redacted fields.
    * `actions: [{:top | :bottom, function}]` : Overrides the default list of actions that are displayed at the top or bottom.
    * `add_actions: [{:top | :bottom, function}]`: Adds actions to the current list.
    * `remove: []`: List of fields to be remove from the list.
      trying to remove non-existing fields will log a warning, but no error will be raised.
    * `title: string | :hide`: Title for the view, a :hide value will make it to be ignored.
    * `sub_title: string | :hide`: Subtitle for the view, a :hide value will disallow its generation.
    * `remove_actions: [function]`: Removes actions from the current list.

    ### :index and :card opts
    * `order_by: [{field, :asc | :desc}]`: Overrides the default order of the list / card.
      By default, the order is by id for numeric id, and by created_at (desc) for compose id or string id.
    * `where: string`: Adds a where like string.

    ### :card :form opts
    * `layout: Uix.Formatter`: Overrides the default layout by using a formatter. See details in the module.
  """
  defmacro define(module, type, parsed_opts) when type in @uix_valid_types do
    module = Macro.expand(module, __CALLER__)
    Code.ensure_compiled(module)

    template = Template.uix_template().generate_view(type, parsed_opts)

    options = [
      engine: Phoenix.LiveView.TagEngine,
      tag_handler: Phoenix.LiveView.HTMLEngine,
      file: __CALLER__.file,
      line: __CALLER__.line + 1,
      caller: __CALLER__,
      source: template
    ]

    quote do
      # Ensure `assigns` is in scope for Phoenix's HEEx engine
      var!(assigns) =
        assigns
        |> var!()
        # Inject the parsed_opts into assigns for template use
        |> Map.put(:_uix, unquote(Macro.escape(parsed_opts)))

      # Compile the template into Phoenix.LiveView.Rendered struct
      unquote(EEx.compile_string(template, options))
    end
  end
end
