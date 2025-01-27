defmodule AuroraUixWeb.Uix do
  @moduledoc """
  Main module for generating user interfaces.
  """

  require Logger

  @uix_template Application.compile_env(:aurora_uix, :template, AuroraUixWeb.Templates.Base)
  @uix_valid_types [:list, :card, :form]

  @doc """
  Defines the generation options for creating a full fledge view.

  ## PARAMETERS
  * `module` (module): Schema module to be used for gathering field information.
  * `type` (atom): Type of view to generate.
    * `:list` : Table like view with selectable fields and action buttons.
    * `:card` : Card like view with configurable card fields.
    * `:form` : Form like view, can have nested elements displayed as block or sections.
  * `opts` (Keyword.t()): List of options, the available ones depends on the type of view.
    ### Common opts
    * `template: Module`: Overrides the module that handles the generation.
      By default uses AuroraUixWeb.AuroraTemplate, which is a sophisticated and highly opinionated template.
      There is also the AuroraUixWeb.PhoenixTemplate, which resembles the phoenix ui.
      The template can also be configured, application wide, by adding :aurora_uix, template: Module.
      New templates can be authored.
    * `fields: []`: Fields to be used, overrides the default list.
      The default list is created with all the fields found in the module, excluding
      the redacted fields.
    * `add: []`: List of fields to be added to the default list, duplicated fields are ignored.
      A proper warning message will be issued.
    * `remove: []`: List of fields to be remove from the list.
      trying to remove non-existing fields will log a warning, but no error will be raised.
    * `title: string | :hide`: Title for the view, a :hide value will make it to be ignored.
    * `sub_title: string | :hide`: Subtitle for the view, a :hide value will disallow its generation.
    * `actions: [{:top | :bottom, function}]` : Overrides the default list of actions that are displayed at the top or bottom.
    * `add_actions: [{:top | :bottom, function}]`: Adds actions to the current list.
    * `remove_actions: [function]`: Removes actions from the current list.

    ### :list and card opts
    * `order_by: [{field, :asc | :desc}]`: Overrides the default order of the list / card.
      By default, the order is by id for numeric id, and by created_at (desc) for compose id or string id.
    * `where: string`: Adds a where like string.

    ### :card :form opts
    * `layout: Uix.Formatter`: Overrides the default layout by using a formatter. See details in the module.


  """
  defmacro define(module, type, opts \\ [])

  defmacro define(_module, type, opts) when type in @uix_valid_types do
    @uix_template.generate(type, opts)
  end

  defmacro define(_module, type, _opts) do
    Logger.warning("""
    The type `#{inspect(type)}` is not implemented.
    Only `#{@uix_valid_types}` are supported.
    """)

    quote do
      ~H"""
      Undefined
      """
    end
  end

  defmacro __using__(_opts) do
    quote do
      require AuroraUixWeb.Uix

      alias AuroraUixWeb.Uix
    end
  end
end
