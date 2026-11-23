defmodule Aurora.UixWeb.Test.Mirror.Handlers.Downloader do
  @moduledoc false

  @doc false
  @spec fetch(binary()) :: {:ok, %{name: binary(), content: binary()}}
  def fetch(value), do: {:ok, %{name: "image.png", content: value}}

  @doc false
  @spec can_download?(binary()) :: boolean()
  def can_download?(value), do: not is_nil(value)
end
