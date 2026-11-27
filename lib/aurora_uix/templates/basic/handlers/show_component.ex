defmodule Aurora.Uix.Templates.Basic.Handlers.ShowComponent do
  @moduledoc """
  The default LiveComponent handler of a generated show component. A layout swaps it with
  `handler_module:` on `show_layout`.

  ## Key Features

    - Everything `Aurora.Uix.Templates.Basic.Handlers.ShowComponentImpl` implements: section
      switching, upload downloads, and open and close requests.

  ## Key Constraints

    - Expects the `:auix` assign in the component socket.
  """

  use Aurora.Uix.Templates.Basic.Handlers.ShowComponentImpl
end
