defmodule Aurora.Uix.Templates.Basic.ConfirmButton do
  @moduledoc """
  A LiveComponent that provides a button with a confirmation modal dialog.

  This component displays an action button that, when clicked, shows a modal
  dialog asking for user confirmation before executing the specified event. It
  handles the complete confirmation flow including showing/hiding the modal and
  forwarding the confirmed event to the appropriate target.

  ## Features

  * Customizable button and modal content via slots
  * Configurable event targets (self or parent LiveView)
  * Internationalized default messages for confirmation dialogs
  * Custom CSS classes for all interactive elements
  * Integrated with Phoenix.LiveView.JS for smooth modal interactions

  ## Required Assigns

  * `:id` - Unique identifier for the component
  * `:value` - Value to be passed with the confirmed event
  * `:event` - Event name to trigger when user confirms the action

  ## Optional Assigns

  * `:content` - Slot for the button's display content
  * `:confirm_message` - Slot for the confirmation question text
  * `:accept_message` - Slot for the accept button label
  * `:cancel_message` - Slot for the cancel button label
  * `:target` - Event target (defaults to `:myself`)
  * `:class` - CSS class for the main button (defaults to
    `"auix-confirm-button--show-action"`)
  * `:accept_button_class` - CSS class for accept button (defaults to
    `"auix-confirm-button--accept-action"`)
  * `:cancel_button_class` - CSS class for cancel button (defaults to
    `"auix-confirm-button--cancel-action"`)

  ## Example

      <.live_component
        module={Aurora.Uix.Templates.Basic.ConfirmButton}
        id="delete-user-btn"
        event="delete_user"
        value={%{user_id: @user.id}}
        target={@myself}
      >
        <:content>Delete User</:content>
        <:confirm_message>
          Are you sure you want to delete this user? This action cannot be
          undone.
        </:confirm_message>
        <:accept_message>Delete</:accept_message>
        <:cancel_message>Cancel</:cancel_message>
      </.live_component>
  """

  use Aurora.Uix.CoreComponentsImporter
  use Aurora.Uix.Gettext
  use Phoenix.LiveComponent
  alias Phoenix.LiveView.JS

  @impl Phoenix.LiveComponent
  @spec update(map(), Phoenix.LiveView.Socket.t()) ::
          {:ok, Phoenix.LiveView.Socket.t()}
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(:id, assigns.id)
     |> assign(:value, assigns.value)
     |> assign(:event, assigns.event)
     |> assign(:type, Map.get(assigns, :type, "button"))
     |> assign(:content, Map.get(assigns, :content))
     |> assign(:confirm_message, Map.get(assigns, :confirm_message))
     |> assign(:accept_message, Map.get(assigns, :accept_message))
     |> assign(:cancel_message, Map.get(assigns, :cancel_message))
     |> assign(:target, Map.get(assigns, :target, :myself))
     |> assign(:class, Map.get(assigns, :class, "auix-confirm-button--show-action"))
     |> assign(
       :accept_button_class,
       Map.get(assigns, :accept_button_class, "auix-confirm-button--accept-action")
     )
     |> assign(
       :cancel_button_class,
       Map.get(assigns, :cancel_button_class, "auix-confirm-button--cancel-action")
     )
     |> assign(:show_modal, false)}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
      <div id={@id} class="auix-confirm-button--container">
        <.button type={@type} class={@class} phx-click="show-modal" phx-target={@myself}>
          <%= if @content do %>
            {render_slot(@content)}
          <% end %>
        </.button>
        <%= if @show_modal do %>
          <.modal id={"#{@id}-modal"} show={@show_modal} on_cancel={JS.push("hide-modal", target: @myself)}>
            <div class="auix-confirm-button--modal">
              <div class="auix-confirm-button--confirm-message">
                <%= if @confirm_message do %>
                  {render_slot(@confirm_message)}
                <% else %>
                  {gettext("Indicate if you want to continue the action")}
                <% end %>
              </div> 
            
              <div class="auix-confirm-button--actions">
                <button type="button" class={@accept_button_class || @class} phx-click={JS.push("hide-modal", target: @myself) |> JS.push(@event, target: @target, value: @value)}>
                  <%= if @accept_message do %>
                    {render_slot(@accept_message)}
                  <% else %>
                    <span>{gettext("Yes")}</span>
                  <% end %>
                </button>  
                <button type="button" class={@cancel_button_class || @class} phx-click={JS.push("hide-modal", target: @myself)}>
                  <%= if @cancel_message do %>
                    {render_slot(@cancel_message)}
                  <% else %>
                    <span>{gettext("No")}</span>
                  <% end %>
                </button>
              </div>
            </div>
          </.modal>
        <% end %>
      </div>
    """
  end

  @doc """
  Shows the confirmation modal dialog.

  Handles the "show-modal" event by setting the `:show_modal` assign to `true`,
  which triggers the modal rendering in the template.

  ## Parameters

  * `event` (String.t()) - The event name (always `"show-modal"`)
  * `params` (map()) - Event parameters (unused)
  * `socket` (Phoenix.LiveView.Socket.t()) - The current socket

  ## Returns

  `{:noreply, Phoenix.LiveView.Socket.t()}` with `:show_modal` set to `true`
  """
  @impl Phoenix.LiveComponent
  @spec handle_event(String.t(), map(), Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_event("show-modal", _params, socket) do
    {:noreply, assign(socket, :show_modal, true)}
  end

  def handle_event("hide-modal", _params, socket) do
    {:noreply, assign(socket, :show_modal, false)}
  end
end
