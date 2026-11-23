defmodule Aurora.UixWeb.Test.Mirror.Handlers.SocketAwareConsumer do
  @moduledoc false

  @doc false
  @spec consume_with_action(Phoenix.LiveView.Socket.t(), list(binary())) :: {:ok, binary()}
  def consume_with_action(socket, binaries) do
    action = to_string(socket.assigns[:action] || :unknown)
    {:ok, "#{action}:#{List.first(binaries, "")}"}
  end
end
