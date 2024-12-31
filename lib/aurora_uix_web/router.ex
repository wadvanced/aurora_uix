defmodule AuroraUixWeb.Router do

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__)
    end
  end

  defmacro register(quoted_schema) do
    {_aliases, _line, modules} = quoted_schema
    schema = Module.concat(modules)
    case Code.ensure_compiled(schema) do
      {:module, schema} ->
        web_module = __CALLER__.module
          |> Module.split()
          |> List.first()

        valid_schema? = function_exported?(schema, :__schema__, 1)
        AuroraUixWeb.RouterHelper.generate_routes(valid_schema?, web_module, schema)

        {:error, _} ->
        AuroraUixWeb.RouterHelper.no_route()
    end
  end
end