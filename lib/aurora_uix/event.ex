defmodule Aurora.Uix.Event do
  @moduledoc """
  A data change published on a schema's topic by `Aurora.Uix.Events`.

  ## Key Features

  - One struct for every data change: created, updated, deleted, or changed in bulk.
  - Carries the primary keys of the affected records, and the records themselves when the
    publisher has them.

  ## Key Constraints

  - `ids` is `[]` for `:changed`.
  - Generated views never render `entities`; they re-read the data with the viewer's own
    actor, filters, sort and page.
  """

  defstruct schema: nil, action: nil, ids: [], entities: []

  @type action() :: :created | :updated | :deleted | :changed

  @type t() :: %__MODULE__{
          schema: module() | nil,
          action: action() | nil,
          ids: list(),
          entities: list(struct())
        }
end
