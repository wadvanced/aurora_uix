defmodule Aurora.UixWeb.Test.Compatibility.FormHandler do
  @moduledoc """
  Form handler that overrides `update/2`, `auix_update/2` and `auix_handle_event/3` with `super`.

  ## Key Features
  - Reports each overridden callback through `Aurora.UixWeb.Test.Compatibility.Probe`.
  - Assigns a custom `:compat_note` key and rejects `:description` at runtime.

  ## Key Constraints
  - Test support only; mirrors the examples in `guides/core/liveview.md`.
  """
  use Aurora.Uix.Templates.Basic.Handlers.FormImpl

  import Aurora.Uix.Templates.Basic.Helpers, only: [assign_auix: 3]

  alias Aurora.Uix.Templates.Basic.Handlers.FormImpl
  alias Aurora.UixWeb.Test.Compatibility.Probe

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    Probe.report(:update)
    super(assigns, socket)
  end

  @impl FormImpl
  def auix_update(assigns, socket) do
    Probe.report(:auix_update)
    {:ok, socket} = super(assigns, socket)

    {:ok,
     socket
     |> assign_auix(:compat_note, "kept")
     |> assign_auix(:fields_to_reject, [:description])}
  end

  @impl FormImpl
  def auix_handle_event("compat_notify", _params, socket) do
    Probe.report({:form_event, "compat_notify"})
    send(self(), {:compat_notify, :form})
    {:noreply, socket}
  end

  def auix_handle_event(event, params, socket), do: super(event, params, socket)
end
