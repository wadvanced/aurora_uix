defmodule AuroraUixTest.DefineCase do
  defmacro __using__(_opts) do
    quote do
      use AuroraUixTestWeb.ConnCase

      import AuroraUixTest.DefineCase

      alias AuroraUixTest.Repo
    end
  end
end
