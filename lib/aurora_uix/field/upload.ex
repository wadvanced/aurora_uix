defmodule Aurora.Uix.Field.Upload do
  @moduledoc """
  Configuration of a file-upload field, held in `Aurora.Uix.Field`'s `upload` key.

  A field with an `upload` is rendered as a managed LiveView upload field:

  ```elixir
  field :uploaded_blob_ref do
    upload allow: [accept: ~w(.xlsx), max_entries: 1, max_file_size: 5_000_000],
           consume: &MyApp.Templates.store_xlsx/1
  end
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
    button. It produces the file; without it no button is rendered. Arity is detected the same
    way as `consume`, with the stored field value as the primary argument:

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
    boolean. When absent, the button is hidden. It is only read when `download` is also set:
    without `download` no button is rendered and the callback is not invoked.
  - `file_info` - **optional** callback describing the stored file, evaluated when the component
    mounts or updates and only when the field holds a value. It follows the same arity dispatch
    as `download` and returns a map with any of `:name` (binary), `:size` (bytes, integer) and
    `:content_type` (binary), or `nil`. The stored file is shown as a card with its name and,
    when given, its type and size. Without a `:name` the card shows the field label.

  ## Key Features
  - Gives the upload options of a field a fixed shape instead of a free-form map.

  ## Key Constraints
  - `consume` is required for the upload to be persisted; the other callbacks are optional.
  """

  alias Phoenix.LiveView.Socket

  defstruct allow: [],
            consume: nil,
            download: nil,
            downloadable?: nil,
            file_info: nil,
            __spark_metadata__: nil

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

  @typedoc "Description of a stored file: its name, size in bytes and content type, all optional."
  @type file_info_result() ::
          %{
            optional(:name) => binary() | nil,
            optional(:size) => non_neg_integer() | nil,
            optional(:content_type) => binary() | nil
          }
          | nil

  @typedoc "Callback describing the stored file, optionally with the socket and field key."
  @type file_info() ::
          (term() -> file_info_result())
          | (Socket.t(), term() -> file_info_result())
          | (Socket.t(), term(), atom() -> file_info_result())

  @type t() :: %__MODULE__{
          allow: keyword(),
          consume: consume() | nil,
          download: download() | nil,
          downloadable?: downloadable() | boolean() | nil,
          file_info: file_info() | nil,
          __spark_metadata__: term()
        }

  @doc """
  Builds an upload configuration from a map or keyword list of its options.

  ## Parameters
  - `attrs` (map() | keyword()) - `:allow`, `:consume`, `:download`, `:downloadable?` and
    `:file_info`.

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
