defmodule Aurora.Uix.Test.EventsTest do
  use ExUnit.Case, async: false

  alias Aurora.Uix.Event
  alias Aurora.Uix.Events
  alias Aurora.Uix.Guides.Blog.Author
  alias Aurora.Uix.Guides.Inventory.Product

  setup do
    previous = Application.get_env(:aurora_uix, :pubsub_server)
    on_exit(fn -> Application.put_env(:aurora_uix, :pubsub_server, previous) end)
    :ok
  end

  test "topic/1 names one topic per schema on both backends" do
    assert Events.topic(Product) == "auix:Aurora.Uix.Guides.Inventory.Product"
    assert Events.topic(Author) == "auix:Aurora.Uix.Guides.Blog.Author"
  end

  test "created/1 and updated/1 take the schema and id from the record" do
    :ok = Events.subscribe(Product)
    :ok = Events.subscribe(Author)

    Events.created(%Product{id: "p-1"})

    assert_receive %Event{
      schema: Product,
      action: :created,
      ids: ["p-1"],
      entities: [%Product{id: "p-1"}]
    }

    Events.updated(%Author{id: "a-1"})

    assert_receive %Event{
      schema: Author,
      action: :updated,
      ids: ["a-1"],
      entities: [%Author{id: "a-1"}]
    }
  end

  test "deleted/2 and changed/1 carry no entities" do
    :ok = Events.subscribe(Product)

    Events.deleted(Product, ["p-1", "p-2"])
    assert_receive %Event{action: :deleted, ids: ["p-1", "p-2"], entities: []}

    Events.changed(Product)
    assert_receive %Event{action: :changed, ids: [], entities: []}
  end

  test "from: excludes the sender only" do
    :ok = Events.subscribe(Product)
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
  end

  test "unsubscribe/1 stops delivery" do
    :ok = Events.subscribe(Product)
    :ok = Events.unsubscribe(Product)

    Events.changed(Product)
    refute_receive %Event{}, 100
  end

  test "refresh/1 and reset_selection/1 message one process" do
    assert Events.refresh() == :ok
    assert_received {Events, :refresh}
    assert Events.reset_selection(self()) == :ok
    assert_received {Events, :reset_selection}
  end

  test "an unset pubsub_server subscribes and broadcasts nothing" do
    Application.delete_env(:aurora_uix, :pubsub_server)

    assert Events.subscribe(Product) == :ok
    assert Registry.lookup(Aurora.Uix.PubSub, Events.topic(Product)) == []

    :ok = Phoenix.PubSub.subscribe(Aurora.Uix.PubSub, Events.topic(Product))
    assert Events.created(%Product{id: "p-1"}) == :ok
    assert Events.changed(Product) == :ok
    refute_receive %Event{}, 100
  end

  test "a pubsub_server that is not started raises on subscribe" do
    Application.put_env(:aurora_uix, :pubsub_server, Aurora.Uix.Test.MissingPubSub)

    assert_raise ArgumentError, fn -> Events.subscribe(Product) end
  end
end
