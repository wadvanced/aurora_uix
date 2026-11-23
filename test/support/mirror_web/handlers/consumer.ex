defmodule Aurora.UixWeb.Test.Mirror.Handlers.Consumer do
  @moduledoc false

  @doc false
  @spec consume_image(list(binary())) :: {:ok, binary()}
  def consume_image([binary]), do: {:ok, binary}
end
