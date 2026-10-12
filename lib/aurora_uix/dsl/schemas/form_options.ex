defmodule Aurora.Uix.Dsl.Schema.FormOptions do
  @moduledoc """
  Spark options schema for form-level configuration.

  ## Key Features

  - Key set mirroring the `:form` layout option defaults
  - Typed entries validated by Spark at compile time

  ## Key Constraints

  - Form layouts only; index and show layouts use their own schemas
  """

  @doc """
  Returns the form options keyword schema.

  ## Returns

  `keyword()` - Spark options schema with one entry per form key.
  """
  @spec schema() :: keyword()
  def schema do
    title = {:or, [:string, {:fun, 1}]}

    [
      edit_title: [type: title, required: false],
      edit_subtitle: [type: title, required: false],
      new_title: [type: title, required: false],
      new_subtitle: [type: title, required: false],
      save_action_label: [type: {:or, [:string, {:fun, 0}]}, required: false],
      record_navigator: [
        type: {:or, [{:in, [:top, :bottom]}, {:list, {:in, [:top, :bottom]}}]},
        required: false
      ],
      unsaved_changes_guard_disabled?: [type: :boolean, required: false],
      edit_handler_module: [type: :module, required: false],
      renderers: [type: {:map, :atom, {:or, [:atom, {:fun, 1}]}}, required: false]
    ]
  end
end
