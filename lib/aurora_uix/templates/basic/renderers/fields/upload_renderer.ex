defmodule Aurora.Uix.Templates.Basic.Renderers.UploadRenderer do
  @moduledoc """
  Renders a file upload field for a form.
  """

  use Aurora.Uix.CoreComponentsImporter
  use Aurora.Uix.Gettext

  @doc """
  Renders a file upload field for a form.
  """
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(%{field: field} = assigns) do
    upload = Map.get(assigns[:uploads] || %{}, field.key)
    assigns = assign(assigns, :upload, upload)

    ~H"""
    <%= if @upload do %>
      <div class="auix-form-field-container">
        <label class="auix-form-field-label">{dt(@field.label)}</label>
        <.live_file_input upload={@upload} />
        <%= for entry <- @upload.entries do %>
          <div class="auix-upload-entry">
            <span class="auix-upload-entry-name">{entry.client_name}</span>
            <span class="auix-upload-entry-progress">{entry.progress}%</span>
            <button
              type="button"
              phx-click="auix_cancel_upload"
              phx-value-field={to_string(@field.key)}
              phx-value-ref={entry.ref}
              phx-target={@auix._myself}
            >
              &times;
            </button>
            <%= for err <- upload_errors(@upload, entry) do %>
              <span class="auix-upload-entry-error">{Phoenix.Naming.humanize(err)}</span>
            <% end %>
          </div>
        <% end %>
        <%= for err <- upload_errors(@upload) do %>
          <span class="auix-upload-error">{Phoenix.Naming.humanize(err)}</span>
        <% end %>
      </div>
    <% end %>
    """
  end
end
