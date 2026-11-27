defmodule Aurora.UixWeb.Test.Mirror.Handlers.Downloader do
  @moduledoc false

  @doc false
  @spec fetch(binary()) :: {:ok, %{name: binary(), content: binary()}}
  def fetch(value), do: {:ok, %{name: "image.png", content: value}}

  @doc false
  @spec info(binary()) :: %{name: binary(), size: non_neg_integer(), content_type: binary()}
  def info(value), do: %{name: "image.png", size: byte_size(value), content_type: "image/png"}

  @doc false
  @spec can_download?(binary()) :: boolean()
  def can_download?(value), do: not is_nil(value)
end
