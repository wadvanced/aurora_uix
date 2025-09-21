defmodule Aurora.Uix.TreePath do
  @moduledoc false
  use Aurora.Uix.AccessHelper

  defstruct [:name, :tag, config: [], opts: [], inner_elements: []]

  @type t() :: %{
          name: atom(),
          tag: atom(),
          config: list(),
          opts: list(),
          inner_elements: list()
        }
end
