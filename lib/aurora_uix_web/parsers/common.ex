defmodule AuroraUixWeb.Parsers.Common do
  @moduledoc """
  Parse common options and adds the module related values.
  """

  @doc """
  Parse module and common options.

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
  """
  @spec parse(map, module, atom, Keyword.t()) :: map
  def parse(parsed_opts, module, type, opts) do
    parsed_opts
  end
end
