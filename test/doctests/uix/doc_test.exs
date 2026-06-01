defmodule Aurora.Uix.Test.Uix.DocTest do
  use ExUnit.Case, async: true

  doctest Aurora.Uix.Field
  doctest Aurora.Uix.Parser, except: [get_options: 2]
  doctest Aurora.Uix.Resource
end
