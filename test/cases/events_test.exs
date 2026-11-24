defmodule Aurora.Uix.Test.EventsTest do
  use ExUnit.Case, async: false

  alias Aurora.Uix.Event
  alias Aurora.Uix.Events
  alias Aurora.Uix.Test.MirrorAsh.ProductLocation
  alias Aurora.Uix.Test.MirrorCtx.Product

  setup do
    previous = Application.get_env(:aurora_uix, :pubsub_server)
    on_exit(fn -> restore_pubsub_server(previous) end)
    :ok
  end

  test "Events names one topic per schema and builds its payloads" do
    assert Events.topic(Product) == "auix:Aurora.Uix.Test.MirrorCtx.Product"
    assert Events.topic(ProductLocation) == "auix:Aurora.Uix.Test.MirrorAsh.ProductLocation"

    subscribe(Product)
    subscribe(ProductLocation)

    Events.created(%Product{id: "p-1"})

    assert_receive %Event{
      schema: Product,
      action: :created,
      ids: ["p-1"],
      entities: [%Product{id: "p-1"}]
    }

    Events.updated(%ProductLocation{id: "a-1"})

    assert_receive %Event{
      schema: ProductLocation,
      action: :updated,
      ids: ["a-1"],
      entities: [%ProductLocation{id: "a-1"}]
    }

    Events.deleted(Product, ["p-1", "p-2"])
    assert_receive %Event{action: :deleted, ids: ["p-1", "p-2"], entities: []}

    Events.changed(Product)
    assert_receive %Event{action: :changed, ids: [], entities: []}
  end

  test "Events delivers to its subscribers and to one process" do
    subscribe(Product)
    test_pid = self()

    task =
      Task.async(fn ->
        :ok = Events.subscribe(Product)
        send(test_pid, :subscribed)

        receive do
          %Event{} = event -> event
        end
      end)

    assert_receive :subscribed
    Events.changed(Product, from: self())
    refute_receive %Event{}, 100
    assert %Event{action: :changed} = Task.await(task)

    :ok = Events.unsubscribe(Product)

    Events.changed(Product)
    refute_receive %Event{}, 100

    assert Events.refresh() == :ok
    assert_received {Events, :refresh}
    assert Events.reset_selection(self()) == :ok
    assert_received {Events, :reset_selection}
  end

  test "Events honours the pubsub_server configuration" do
    Application.delete_env(:aurora_uix, :pubsub_server)

    # A topic of its own: LiveViews of other tests, and the registry entry of a test process
    # that has just ended, can still be subscribed to the Product topic.
    assert Events.subscribe(__MODULE__) == :ok
    assert Registry.lookup(Aurora.Uix.PubSub, Events.topic(__MODULE__)) == []

    :ok = Phoenix.PubSub.subscribe(Aurora.Uix.PubSub, Events.topic(Product))
    on_exit(fn -> Phoenix.PubSub.unsubscribe(Aurora.Uix.PubSub, Events.topic(Product)) end)
    assert Events.created(%Product{id: "p-1"}) == :ok
    assert Events.changed(Product) == :ok
    refute_receive %Event{}, 100

    Application.put_env(:aurora_uix, :pubsub_server, Aurora.Uix.Test.MissingPubSub)

    assert_raise ArgumentError, fn -> Events.subscribe(Product) end
  end

  @spec subscribe(module()) :: :ok
  defp subscribe(schema) do
    :ok = Events.subscribe(schema)
    on_exit(fn -> Events.unsubscribe(schema) end)
  end

  @spec restore_pubsub_server(module() | nil) :: :ok
  defp restore_pubsub_server(nil), do: Application.delete_env(:aurora_uix, :pubsub_server)

  defp restore_pubsub_server(server),
    do: Application.put_env(:aurora_uix, :pubsub_server, server)
end
