defmodule Aurora.Uix.TreePath do
  use Aurora.Uix.AccessHelper
  defstruct [:name, :tag, config: [], opts: [], inner_elements: []]
end
