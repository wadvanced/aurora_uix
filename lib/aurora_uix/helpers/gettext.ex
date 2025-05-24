defmodule Aurora.Uix.Web.Gettext do
  @moduledoc """
  Provides dynamic gettext functionality where the backend is determined by an environment variable.
  """

  @doc """
  Injects Gettext functionality with configurable backend support.

  ## Options

    * `:backend` - The Gettext backend module to use. Defaults to Aurora.Uix.Web.GettextBackend

  ## Examples

      # Basic usage with default backend
      defmodule MyApp.Gettext do
        use Aurora.Uix.Web.Gettext
      end

      # With custom backend
      defmodule MyApp.Gettext do
        use Aurora.Uix.Web.Gettext, backend: MyCustomBackend
      end

      # Usage in runtime
      MyApp.Gettext.gettext("Hello") # => "Hola" (depending on locale)

  The backend can also be configured via application config:

      config :aurora_uix, :gettext_backend, MyCustomBackend
  """
  @spec __using__(keyword) :: Macro.t()
  defmacro __using__(opts) do
    default_backend = opts[:backend] || Aurora.Uix.Web.GettextBackend

    backend_module =
      Application.get_env(:aurora_uix, :gettext_backend, default_backend)

    # For deprecated implementation
    gettext_module = Application.get_env(:aurora_uix, :gettext)

    implementation =
      if is_nil(gettext_module) do
        quote do
          use Gettext, backend: unquote(backend_module)
        end
      else
        quote do
          import unquote(gettext_module)
        end
      end

    quote do
      unquote(implementation)

      @doc """
      Provides the configured backend
      """
      def backend do
        unquote(backend_module)
      end
    end
  end
end
