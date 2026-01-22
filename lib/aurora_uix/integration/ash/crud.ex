defmodule Aurora.Uix.Integration.Ash.Crud do
  alias Aurora.Uix.Integration.Ash.QueryParser

  def list(action_module, action_name, options \\ []) do
    {:ok, result} =
      action_module
      |> Ash.Query.for_read(action_name)
      |> QueryParser.parse(options)
      |> Ash.read()

    %Aurora.Ctx.Pagination{
      entries: result,
      entries_count: Enum.count(result),
      pages_count: 1,
      per_page: :infinity
    }
  end
end
