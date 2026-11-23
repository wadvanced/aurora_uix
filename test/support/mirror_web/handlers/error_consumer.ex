defmodule Aurora.UixWeb.Test.Mirror.Handlers.ErrorConsumer do
  @moduledoc false

  @doc false
  @spec fail(list(binary())) :: {:error, binary()}
  def fail(_binaries), do: {:error, "bad file"}
end
