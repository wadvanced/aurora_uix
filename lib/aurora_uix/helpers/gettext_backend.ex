defmodule Aurora.Uix.Web.GettextBackend do
  @moduledoc """
  Fallback module providing internationalization (I18n) for Aurora UIX using a Gettext-based API.

  ## Purpose
  Acts as the default Gettext backend for Aurora UIX, enabling translation and localization support
  when no custom backend is specified.

  ## Key Constraints
  - Used as the default backend unless overridden by configuration or options.
  """
  use Gettext.Backend, otp_app: :aurora_uix
end
