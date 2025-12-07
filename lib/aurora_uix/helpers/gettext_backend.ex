defmodule Aurora.Uix.GettextBackend do
  @moduledoc """
  Default Gettext backend module for Aurora UIX providing internationalization (I18n) support.
  """
  use Gettext.Backend, otp_app: :aurora_uix
end
