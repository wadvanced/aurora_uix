defmodule Aurora.Uix.Field.Upload do
  @moduledoc """
  Configuration of a file-upload field, held in `Aurora.Uix.Field`'s `upload` key.

  A field with an `upload` is rendered as a managed LiveView upload field:

  ```elixir
  field :uploaded_blob_ref,
    data: %{
      upload: %{
        allow:   [accept: ~w(.xlsx), max_entries: 1, max_file_size: 5_000_000],
        consume: &MyApp.Templates.store_xlsx/1
      }
    }
  ```

  - `allow` - keyword list forwarded to `Phoenix.LiveView.allow_upload/3`
    (`:accept`, `:max_entries`, `:max_file_size`, `:auto_upload?`, …).
  - `consume` - callback invoked with the consumed binaries. Arity is detected
    automatically via `Function.info/1`:

    | Arity | Call shape                           | When to use                                     |
    |-------|--------------------------------------|-------------------------------------------------|
    | 1     | `consume.(binaries)`                 | Pure transform; no socket context needed.       |
    | 2     | `consume.(socket, binaries)`         | Needs socket assigns (e.g. `current_user`).     |
    | 3     | `consume.(socket, binaries, key)`    | One callback handles multiple upload fields.    |

    All arities must return one of:
    - `{:ok, value}` - `value` is written onto the entity params under the field key.
    - `:no_change` - the field is left untouched; no-file-selected is also short-circuited
      to `:no_change` so the callback need not handle an empty list.
    - `{:error, reason}` - save aborts and `reason` is shown as an error flash.

    The socket is **never** returned by `consume`; use a `handle_event("save", …)` override
    for socket mutations on save.
  - `download` - **optional** producer callback invoked when the user clicks the Download
    button. Its presence is the opt-in master switch: **no `download` means no button is
    rendered.** Arity is detected the same way as `consume`, with the stored field value as
    the primary argument:

    | Arity | Call shape                          | When to use                                  |
    |-------|-------------------------------------|----------------------------------------------|
    | 1     | `download.(value)`                  | Pure retrieval; no socket context needed.    |
    | 2     | `download.(socket, value)`          | Needs socket assigns (e.g. `current_user`).  |
    | 3     | `download.(socket, value, key)`     | One callback handles multiple upload fields. |

    All arities must return one of:
    - `{:ok, %{name: filename, content: binary}}` - triggers a client-side file download.
      An optional `:content_type` key may be included in the map.
    - `:no_download` - does nothing.
    - `{:error, reason}` - `reason` is shown as an error flash.

    Actor-based visibility should be enforced here (return `{:error, …}` or `:no_download`),
    since the socket (and thus `current_user`) is available to arity-2 and arity-3 callbacks.
  - `downloadable?` - **optional** gate evaluated when the component mounts or updates. A
    boolean, or a callback following the same arity dispatch as `download`, returning a
    boolean. Only evaluated when `download` is also configured. When absent, the button is
    hidden.

  ## Key Features
  - Gives the upload options of a field a fixed shape instead of a free-form map.

  ## Key Constraints
  - `consume` is required for the upload to be persisted; the other callbacks are optional.
  """

  alias Phoenix.LiveView.Socket

  defstruct allow: [], consume: nil, download: nil, downloadable?: nil

  @typedoc "Result of `consume`: the value to store, no change, or an error shown as a flash."
  @type consume_result() :: {:ok, term()} | :no_change | {:error, term()}

  @typedoc "Callback receiving the consumed file binaries, optionally with the socket and field key."
  @type consume() ::
          ([binary()] -> consume_result())
          | (Socket.t(), [binary()] -> consume_result())
          | (Socket.t(), [binary()], atom() -> consume_result())

  @typedoc "Result of `download`: the file to send, nothing, or an error shown as a flash."
  @type download_result() ::
          {:ok,
           %{
             required(:name) => binary(),
             required(:content) => binary(),
             optional(:content_type) => binary()
           }}
          | :no_download
          | {:error, term()}

  @typedoc "Callback receiving the stored field value, optionally with the socket and field key."
  @type download() ::
          (term() -> download_result())
          | (Socket.t(), term() -> download_result())
          | (Socket.t(), term(), atom() -> download_result())

  @typedoc "Gate receiving the stored field value, optionally with the socket and field key."
  @type downloadable() ::
          (term() -> boolean())
          | (Socket.t(), term() -> boolean())
          | (Socket.t(), term(), atom() -> boolean())

  @type t() :: %__MODULE__{
          allow: keyword(),
          consume: consume() | nil,
          download: download() | nil,
          downloadable?: downloadable() | boolean() | nil
        }

  @doc """
  Builds an upload configuration from a map or keyword list of its options.

  ## Parameters
  - `attrs` (map() | keyword()) - `:allow`, `:consume`, `:download` and `:downloadable?`.

  ## Returns
  `Aurora.Uix.Field.Upload.t()` - The upload configuration.

  ## Examples
  ```elixir
  Aurora.Uix.Field.Upload.new(%{allow: [max_entries: 1], consume: &MyApp.store/1})
  # => %Aurora.Uix.Field.Upload{allow: [max_entries: 1], consume: &MyApp.store/1, ...}
  ```
  """
  @spec new(map() | keyword()) :: t()
  def new(attrs), do: struct(__MODULE__, attrs)
end
