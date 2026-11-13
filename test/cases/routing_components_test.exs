defmodule Aurora.Uix.Test.RoutingComponentsTest do
  use ExUnit.Case, async: true
  use Aurora.Uix.CoreComponentsImporter

  import Aurora.Uix.Templates.Basic.RoutingComponents
  import Phoenix.Component, only: [sigil_H: 2]
  import Phoenix.LiveViewTest

  @spec targeted_link(map()) :: Phoenix.LiveView.Rendered.t()
  defp targeted_link(assigns), do: ~H|<.auix_link patch="/x" phx-target="#c">x</.auix_link>|

  @spec targeted_link_back(map()) :: Phoenix.LiveView.Rendered.t()
  defp targeted_link_back(assigns),
    do: ~H|<.auix_link_back phx-target="#c">x</.auix_link_back>|

  @spec targeted_back(map()) :: Phoenix.LiveView.Rendered.t()
  defp targeted_back(assigns), do: ~H|<.auix_back phx-target="#c">x</.auix_back>|

  @spec plain_link(map()) :: Phoenix.LiveView.Rendered.t()
  defp plain_link(assigns), do: ~H|<.auix_link patch="/x">x</.auix_link>|

  @spec query(function(), binary()) :: LazyHTML.t()
  defp query(component, selector) do
    component
    |> render_component(%{})
    |> LazyHTML.from_fragment()
    |> LazyHTML.query(selector)
  end

  test "routing links pass phx-target through" do
    forward = query(&targeted_link/1, "a[phx-click='auix_route_forward'][phx-target='#c']")
    link_back = query(&targeted_link_back/1, "a[phx-click='auix_route_back'][phx-target='#c']")
    back = query(&targeted_back/1, "a[phx-click='auix_route_back'][phx-target='#c']")
    plain = query(&plain_link/1, "a[phx-target]")

    assert Enum.count(forward) == 1
    assert Enum.count(link_back) == 1
    assert Enum.count(back) == 1
    assert Enum.empty?(plain)
  end
end
