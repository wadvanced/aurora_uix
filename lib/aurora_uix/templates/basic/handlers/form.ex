defmodule Aurora.Uix.Templates.Basic.Handlers.Form do
  @moduledoc """
  The default LiveComponent handler of a generated form component. A layout swaps it with
  `handler_module:` on `edit_layout`.

  ## Key Features

    - Everything `Aurora.Uix.Templates.Basic.Handlers.FormImpl` implements: validation, saving,
      uploads, section switching and the unsaved-changes guard.

  ## Key Constraints

    - Expects the `:auix` assign in the component socket.
  """

  use Aurora.Uix.Templates.Basic.Handlers.FormImpl
end
