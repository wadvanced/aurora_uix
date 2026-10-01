defmodule Aurora.Uix.Events do
  @moduledoc """
  Publish and subscribe to data changes, and send commands to an index LiveView.

  ## Key Features

  - One topic per schema or Ash resource: `"auix:" <> inspect(schema)`.
  - Publishers for host code: `created/2`, `updated/2`, `deleted/3`, `changed/2`.
  - Index commands `refresh/1` and `reset_selection/1`, sent to one LiveView process.

  ## Key Constraints

  - The PubSub server is read at call time from `config :aurora_uix, pubsub_server:`. The host
    supervises it; this module starts no process.
  - With `:pubsub_server` unset, subscribing and publishing do nothing and return `:ok`.
  - The primary key is read with `schema.__schema__(:primary_key)`, which Ecto schemas and Ash
    resources both define.
  """

  alias Aurora.Uix.Event

  @doc """
  Returns the topic for a schema or Ash resource.

  ## Parameters
  - `schema` (module()) - The schema or Ash resource module.

  ## Returns
  binary() - `"auix:" <> inspect(schema)`.
  """
  @spec topic(module()) :: binary()
  def topic(schema) when is_atom(schema), do: "auix:" <> inspect(schema)

  @doc """
  Subscribes the calling process to the schema's topic.

  ## Parameters
  - `schema` (module()) - The schema or Ash resource module.

  ## Returns
  `:ok | {:error, term()}` - `:ok` without subscribing when `:pubsub_server` is not configured.
  """
  @spec subscribe(module()) :: :ok | {:error, term()}
  def subscribe(schema) do
    case pubsub_server() do
      nil -> :ok
      server -> Phoenix.PubSub.subscribe(server, topic(schema))
    end
  end

  @doc """
  Unsubscribes the calling process from the schema's topic.

  ## Parameters
  - `schema` (module()) - The schema or Ash resource module.

  ## Returns
  `:ok`
  """
  @spec unsubscribe(module()) :: :ok
  def unsubscribe(schema) do
    case pubsub_server() do
      nil -> :ok
      server -> Phoenix.PubSub.unsubscribe(server, topic(schema))
    end
  end

  @doc """
  Publishes a `:created` event for a record; the schema is the record's struct module.

  ## Parameters
  - `entity` (struct()) - The created record.
  - `opts` (keyword()) - `from: pid` skips delivery to that process.

  ## Returns
  `:ok | {:error, term()}`
  """
  @spec created(struct(), keyword()) :: :ok | {:error, term()}
  def created(%schema{} = entity, opts \\ []),
    do:
      publish(
        %Event{schema: schema, action: :created, ids: [entity_id(entity)], entities: [entity]},
        opts
      )

  @doc """
  Publishes an `:updated` event for a record; the schema is the record's struct module.

  ## Parameters
  - `entity` (struct()) - The updated record.
  - `opts` (keyword()) - `from: pid` skips delivery to that process.

  ## Returns
  `:ok | {:error, term()}`
  """
  @spec updated(struct(), keyword()) :: :ok | {:error, term()}
  def updated(%schema{} = entity, opts \\ []),
    do:
      publish(
        %Event{schema: schema, action: :updated, ids: [entity_id(entity)], entities: [entity]},
        opts
      )

  @doc """
  Publishes a `:deleted` event listing the primary keys of the deleted records.

  ## Parameters
  - `schema` (module()) - The schema or Ash resource module.
  - `ids` (list()) - Primary-key values of the deleted records.
  - `opts` (keyword()) - `from: pid` skips delivery to that process.

  ## Returns
  `:ok | {:error, term()}`
  """
  @spec deleted(module(), list(), keyword()) :: :ok | {:error, term()}
  def deleted(schema, ids, opts \\ []) when is_list(ids),
    do: publish(%Event{schema: schema, action: :deleted, ids: ids}, opts)

  @doc """
  Publishes a `:changed` event: the schema's data changed in a way that is not listed record by record.

  ## Parameters
  - `schema` (module()) - The schema or Ash resource module.
  - `opts` (keyword()) - `from: pid` skips delivery to that process.

  ## Returns
  `:ok | {:error, term()}`
  """
  @spec changed(module(), keyword()) :: :ok | {:error, term()}
  def changed(schema, opts \\ []), do: publish(%Event{schema: schema, action: :changed}, opts)

  @doc """
  Asks an index LiveView to re-read its current page.

  ## Parameters
  - `pid` (pid()) - The index LiveView process. Defaults to the caller.

  ## Returns
  `:ok`
  """
  @spec refresh(pid()) :: :ok
  def refresh(pid \\ self()) do
    send(pid, {__MODULE__, :refresh})
    :ok
  end

  @doc """
  Asks an index LiveView to clear its selection and re-read its current page.

  ## Parameters
  - `pid` (pid()) - The index LiveView process. Defaults to the caller.

  ## Returns
  `:ok`
  """
  @spec reset_selection(pid()) :: :ok
  def reset_selection(pid \\ self()) do
    send(pid, {__MODULE__, :reset_selection})
    :ok
  end

  ## PRIVATE

  @spec publish(Event.t(), keyword()) :: :ok | {:error, term()}
  defp publish(%Event{} = event, opts) do
    case pubsub_server() do
      nil -> :ok
      server -> broadcast(server, event, Keyword.get(opts, :from))
    end
  end

  @spec broadcast(atom(), Event.t(), pid() | nil) :: :ok | {:error, term()}
  defp broadcast(server, event, nil),
    do: Phoenix.PubSub.broadcast(server, topic(event.schema), event)

  defp broadcast(server, event, from),
    do: Phoenix.PubSub.broadcast_from(server, from, topic(event.schema), event)

  # Same shape as `Aurora.Uix.Templates.Basic.Helpers.primary_key_value/2`: a single key yields
  # its value, a composite key a list of values.
  @spec entity_id(struct()) :: term()
  defp entity_id(%schema{} = entity) do
    case schema.__schema__(:primary_key) do
      [key] -> Map.get(entity, key)
      keys -> Enum.map(keys, &Map.get(entity, &1))
    end
  end

  @spec pubsub_server() :: atom() | nil
  defp pubsub_server, do: Application.get_env(:aurora_uix, :pubsub_server)
end
