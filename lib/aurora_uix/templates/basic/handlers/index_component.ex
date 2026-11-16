defmodule Aurora.Uix.Templates.Basic.Handlers.IndexComponent do
  @moduledoc """
  Provides the default LiveComponent handler of a generated index component in Aurora UIX
  templates.

  It runs the list of a resource on the socket of the component and reports what the user did
  to its host as intents. A layout swaps it with `component_handler_module:` on `index_columns`.

  ## Key Features

    - Lists the records of a resource with filters, sort, pagination and selection.
    - Reports the row and header actions as `{:open, action, id}` and deletions as
      `{:deleted, ids}`.
    - Reports a page change as `{:page, page}`.
    - Re-reads its page on an `Aurora.Uix.Event` given through `send_update/3`.

  ## Key Constraints

    - Expects assigns to include an `:auix` map with the compiled options of the component.
    - Never navigates: the host decides what an intent does.
    - Designed for use within Aurora UIX LiveView templates.
  """

  use Aurora.Uix.Templates.Basic.Handlers.IndexComponentImpl
end
