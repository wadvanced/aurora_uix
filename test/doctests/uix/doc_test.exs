defmodule Aurora.Uix.Test.Uix.DocTest do
  use ExUnit.Case, async: true

  doctest Aurora.Uix.Field
  doctest Aurora.Uix.Helpers.Common, only: [safe_existing_atom: 1]
  doctest Aurora.Uix.Parser, except: [get_options: 2]
  doctest Aurora.Uix.Resource
end
