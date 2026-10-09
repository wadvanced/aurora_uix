defmodule Aurora.Uix.Test.IdSelectorGuardTest do
  use ExUnit.Case, async: true

  alias Aurora.Uix.Templates.Basic.CoreComponents

  test "uix_id_selector/2 builds an attribute selector valid for any id" do
    assert CoreComponents.uix_id_selector("019b-7dd2") == ~s([id="019b-7dd2"])
    assert CoreComponents.uix_id_selector("modal", "-bg") == ~s([id="modal-bg"])
    assert CoreComponents.uix_id_selector(~s(a"b)) == ~s([id="a\\"b"])
  end

  test "lib does not build id selectors by interpolating dynamic ids" do
    offenders =
      "lib/**/*.ex"
      |> Path.wildcard()
      |> Enum.reject(&String.contains?(&1, "/guides/"))
      |> Enum.flat_map(fn path ->
        path
        |> File.stream!()
        |> Stream.with_index(1)
        |> Enum.filter(fn {line, _} ->
          line =~ ~r/(to|target): *"##\{/ or line =~ ~r/_(show|hide)\("##\{/
        end)
        |> Enum.map(fn {_, n} -> "#{path}:#{n}" end)
      end)

    assert offenders == []
  end
end
