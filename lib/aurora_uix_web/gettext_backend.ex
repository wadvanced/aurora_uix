defmodule AuroraUixWeb.GettextBackend do
  @moduledoc """
  A fallback module that provides Internationalization with a gettext-based API.
  """
  use Gettext.Backend, otp_app: :aurora_uix
end
