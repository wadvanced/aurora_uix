defmodule Aurora.Uix.Theme do
  @callback rule(rule :: atom()) :: binary()

  @callback rules() :: binary()

  @optional_callbacks rules: 0
end
