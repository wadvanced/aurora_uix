defmodule Aurora.Uix.Dsl.Schema.ShowOptions do
  @moduledoc """
  Spark options schema for show-level configuration.

  ## Key Features

  - Key set mirroring the `:show` layout option defaults
  - Typed entries validated by Spark at compile time

  ## Key Constraints

  - Show layouts only; index and form layouts use their own schemas
  """

  @doc """
  Returns the show options keyword schema.

  ## Returns

  `keyword()` - Spark options schema with one entry per show key.
  """
  @spec schema() :: keyword()
  def schema do
    title = {:or, [:string, {:fun, 1}]}
    label = {:or, [:string, {:fun, 0}]}

    [
      page_title: [type: title, required: false],
      page_subtitle: [type: title, required: false],
      edit_action_label: [type: label, required: false],
      back_action_label: [type: label, required: false],
      record_navigator: [
        type: {:or, [{:in, [:top, :bottom]}, {:list, {:in, [:top, :bottom]}}]},
        required: false
      ],
      show_handler_module: [type: :module, required: false],
      renderers: [type: {:map, :atom, {:or, [:atom, {:fun, 1}]}}, required: false]
    ]
  end
end
