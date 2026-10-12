defmodule Aurora.Uix.Dsl.Schema.ActionOptions do
  @moduledoc """
  Spark options schema for layout action configuration.

  ## Key Features

  - One entry per action option name in `Aurora.Uix.Action.action_option_names/0`
  - Value types following the `{name, &fun/1}` and bare-name shapes

  ## Key Constraints

  - Derived at compile time; new action groups appear without edits here
  """

  alias Aurora.Uix.Action

  @action_names Action.action_option_names()

  @doc """
  Returns the action options keyword schema.

  ## Returns

  `keyword()` - Spark options schema with one entry per action option name.
  """
  @spec schema() :: keyword()
  def schema do
    Enum.map(@action_names, fn name ->
      prefix = name |> Atom.to_string() |> String.split("_") |> hd()

      type =
        if prefix == "remove" do
          :atom
        else
          {:tuple, [:atom, {:fun, 1}]}
        end

      {name, [type: type, required: false]}
    end)
  end
end
