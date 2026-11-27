defmodule Aurora.Uix.Templates.Basic.Renderers.UploadRenderer do
  @moduledoc """
  Renders a file upload field in the form and show views.
  """

  use Aurora.Uix.CoreComponentsImporter
  use Aurora.Uix.GettextResolver

  @doc """
  Renders a file upload field.

  Both views render the Download button when the field's `download` and `downloadable?` options
  allow it (see `Aurora.Uix.Field.Upload`). Without the button, the show view says "No file" when
  the record has none. The form view renders the file input and the entry list when the field is
  neither readonly nor disabled.
  """
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(%{auix: %{layout_type: :show, entity: entity}, field: field} = assigns) do
    file_ref = Map.get(entity || %{}, field.key)
    downloadable? = get_in(assigns, [:auix, :upload_downloadable, field.key]) || false
    assigns = assigns |> assign(:file_ref, file_ref) |> assign(:downloadable?, downloadable?)

    ~H"""
    <div class="auix-form-field-container">
      <.label>{dt(@field.label)}</.label>
      <%= if @downloadable? do %>
        <.button
          type="button"
          phx-click="auix_download_upload"
          phx-value-field={to_string(@field.key)}
          phx-target={@auix._myself}
        >
          {dt("Download")}
        </.button>
      <% else %>
        <%= if is_nil(@file_ref) do %>
          <span>{dt("No file")}</span>
        <% end %>
      <% end %>
    </div>
    """
  end

  def render(%{field: field} = assigns) do
    upload = Map.get(assigns[:uploads] || %{}, field.key)
    file_ref = Map.get((assigns[:auix] || %{})[:entity] || %{}, field.key)
    downloadable? = get_in(assigns, [:auix, :upload_downloadable, field.key]) || false

    assigns =
      assigns
      |> assign(:upload, upload)
      |> assign(:file_ref, file_ref)
      |> assign(:downloadable?, downloadable?)

    ~H"""
    <%= if @upload do %>
      <div class="auix-form-field-container">
        <.label>{dt(@field.label)}</.label>
        <%= if @downloadable? do %>
          <.button
            type="button"
            phx-click="auix_download_upload"
            phx-value-field={to_string(@field.key)}
            phx-target={@auix._myself}
          >
            {dt("Download")}
          </.button>
        <% end %>
        <%= unless @field.readonly or @field.disabled do %>
          <.live_file_input upload={@upload} />
          <%= for entry <- @upload.entries do %>
            <div class="auix-upload-entry">
              <span>{entry.client_name}</span>
              <span>{entry.progress}%</span>
              <.button
                type="button"
                phx-click="auix_cancel_upload"
                phx-value-field={to_string(@field.key)}
                phx-value-ref={entry.ref}
                phx-target={@auix._myself}
              >
                &times;
              </.button>
              <%= for err <- upload_errors(@upload, entry) do %>
                <.error>{Phoenix.Naming.humanize(err)}</.error>
              <% end %>
            </div>
          <% end %>
          <%= for err <- upload_errors(@upload) do %>
            <.error>{Phoenix.Naming.humanize(err)}</.error>
          <% end %>
        <% end %>
      </div>
    <% end %>
    """
  end
end
