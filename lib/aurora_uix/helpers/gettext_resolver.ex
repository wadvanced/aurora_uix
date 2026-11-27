defmodule Aurora.Uix.GettextResolver do
  @moduledoc """
  Injects Gettext functionality with configurable backend support.

  Sets up the module to use Gettext with a configurable backend. The backend is resolved by:
  1. The `:gettext_backend` application configuration, which wins over the option.
  2. The `:backend` option.
  3. `Aurora.Uix.GettextBackend`.

  If a deprecated `:gettext` application configuration exists, it imports that module
  instead of using the standard Gettext setup.

  The default backend reads the `aurora_uix` dependency's translations only, never the host
  application's, so it returns the English source strings. To translate, configure the host's
  backend with `:gettext_backend` (see `Aurora.Uix.GettextBackend`).

  ## Options
  - `:backend` (module()) - Optional. The Gettext backend of the module when
    `:gettext_backend` is not configured.

  ## Examples
  ```elixir
  defmodule MyAppWeb.ProductActions do
    use Aurora.Uix.GettextResolver

    def archive_label, do: dt("Archive")
  end
  ```

  `dt/1` is a private macro of the using module. It translates in the domain of
  `config :aurora_uix, :gettext_domain` (default `"default"`): `dt("Archive")` gives the host's
  translation with `gettext_backend: MyAppWeb.Gettext` and its locale set.

  ## Configuration
  ```elixir
  config :aurora_uix, :gettext_backend, MyAppWeb.Gettext
  ```
  """

  require Logger

  @gettext_domain Application.compile_env(:aurora_uix, :gettext_domain, "default")

  @doc false
  @spec __using__(keyword()) :: Macro.t()
  defmacro __using__(opts) do
    default_backend = opts[:backend] || Aurora.Uix.GettextBackend

    backend_module =
      Application.get_env(:aurora_uix, :gettext_backend, default_backend)

    dt_implementation = domain_dt_implementation(@gettext_domain)

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
      @gettext_domain unquote(@gettext_domain)
      unquote(dt_implementation)

      @spec gettext_backend() :: module()
      defp gettext_backend do
        unquote(backend_module)
      end
    end
  end

  @spec domain_dt_implementation(binary() | nil) :: Macro.t()
  defp domain_dt_implementation(gettext_domain) do
    quote do
      defmacrop dt(msgid) do
        domain = unquote(gettext_domain)

        case msgid do
          binary when is_binary(binary) ->
            quote do: Gettext.dgettext(gettext_backend(), unquote(domain), unquote(binary))

          _dynamic ->
            quote do
              if is_binary(unquote(msgid)) do
                Gettext.dgettext(gettext_backend(), unquote(domain), unquote(msgid))
              else
                unquote(msgid)
              end
            end
        end
      end
    end
  end
end
