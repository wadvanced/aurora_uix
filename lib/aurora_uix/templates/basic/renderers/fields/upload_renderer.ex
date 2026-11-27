defmodule Aurora.Uix.Templates.Basic.Renderers.UploadRenderer do
  @moduledoc """
  Renders a file upload field for a form or a show page.

  ## Key Features
  - A stored file is shown as a card: a file icon, its name, its type and size when known, and a
    download button when the field is downloadable.
  - The name, type and size come from the precomputed `auix.upload_file_info`; without a name the
    card shows the field label.
  - In the form, a stored file's card offers a replace button and an empty field offers a
    "Choose file" button with the accepted types. Both open the visually hidden file input.
  - Selected entries are listed as cards with their progress and a cancel button.
  - The field container carries `data-upload-field` with the field key, a stable hook for
    selectors.

  ## Key Constraints
  - Runs no user-provided code: visibility and file descriptions are precomputed in
    `auix_update/2` by `Aurora.Uix.Templates.Basic.Helpers`.
  """

  use Aurora.Uix.CoreComponentsImporter
  use Aurora.Uix.GettextResolver

  @kilobyte 1024
  @megabyte 1024 * 1024

  @doc """
  Renders a file upload field.

  In show mode, renders the stored file's card, or a "No file" indicator otherwise.
  In edit mode, renders the stored file's card, with a replace button when the field is editable.
  The file picker and entry list are only rendered when the field is not readonly or disabled.
  """
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(%{auix: %{layout_type: :show}, field: field} = assigns) do
    assigns = assign_file(assigns, field)

    ~H"""
    <div class="auix-form-field-container" data-upload-field={@field.key}>
      <.label>{dt(@field.label)}</.label>
      <%= if is_nil(@file_ref) do %>
        <span class="auix-upload-empty">{dt("No file")}</span>
      <% else %>
        <.file_card
          field={@field}
          file_info={@file_info}
          downloadable?={@downloadable?}
          upload={nil}
          target={@auix._myself}
        />
      <% end %>
    </div>
    """
  end

  def render(%{field: field} = assigns) do
    upload = Map.get(assigns[:uploads] || %{}, field.key)
    editable? = not (field.readonly or field.disabled)

    assigns =
      assigns
      |> assign_file(field)
      |> assign(:upload, upload)
      |> assign(:editable?, editable?)

    ~H"""
    <%= if @upload do %>
      <div class="auix-form-field-container" data-upload-field={@field.key}>
        <.label>{dt(@field.label)}</.label>
        <.file_card
          :if={not is_nil(@file_ref)}
          field={@field}
          file_info={@file_info}
          downloadable?={@downloadable?}
          upload={if @editable?, do: @upload}
          target={@auix._myself}
        />
        <%= if @editable? do %>
          <div :if={is_nil(@file_ref)} class="auix-upload-picker-container">
            <label for={@upload.ref} class="auix-upload-picker">
              <.icon name="hero-arrow-up-tray" class="auix-icon-size-4" />
              <span>{dt("Choose file")}</span>
            </label>
            <span :if={accept_hint(@upload.accept)} class="auix-upload-hint">
              {accept_hint(@upload.accept)}
            </span>
          </div>
          <.live_file_input upload={@upload} class="auix-upload-input" />
          <%= for entry <- @upload.entries do %>
            <div class="auix-upload-entry">
              <span class="auix-upload-file-icon">
                <.icon name="hero-document" class="auix-icon-size-5" />
              </span>
              <span class="auix-upload-file-details">
                <span class="auix-upload-file-name">{entry.client_name}</span>
                <span class="auix-upload-file-meta">{entry.progress}%</span>
              </span>
              <.button
                type="button"
                class="auix-button--iconized auix-upload-file-action"
                title={dt("Cancel")}
                phx-click="auix_cancel_upload"
                phx-value-field={to_string(@field.key)}
                phx-value-ref={entry.ref}
                phx-target={@auix._myself}
              >
                <.icon name="hero-x-mark" class="auix-icon-size-4" />
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

  ## PRIVATE

  @spec file_card(map()) :: Phoenix.LiveView.Rendered.t()
  defp file_card(assigns) do
    assigns =
      assigns
      |> assign(:name, file_name(assigns.file_info, assigns.field))
      |> assign(:meta, file_meta(assigns.file_info))

    ~H"""
    <div class="auix-upload-file">
      <span class="auix-upload-file-icon">
        <.icon name="hero-document" class="auix-icon-size-5" />
      </span>
      <span class="auix-upload-file-details">
        <span class="auix-upload-file-name">{@name}</span>
        <span :if={@meta} class="auix-upload-file-meta">{@meta}</span>
      </span>
      <.button
        :if={@downloadable?}
        type="button"
        class="auix-button--iconized auix-upload-file-action"
        title={dt("Download")}
        phx-click="auix_download_upload"
        phx-value-field={to_string(@field.key)}
        phx-target={@target}
      >
        <.icon name="hero-arrow-down-tray" class="auix-icon-size-4" />
      </.button>
      <label
        :if={@upload}
        for={@upload.ref}
        class="auix-upload-file-action auix-upload-file-replace"
        title={dt("Replace file")}
      >
        <.icon name="hero-arrow-up-tray" class="auix-icon-size-4" />
      </label>
    </div>
    """
  end

  @spec assign_file(map(), map()) :: map()
  defp assign_file(assigns, field) do
    auix = assigns[:auix] || %{}

    assigns
    |> assign(:file_ref, Map.get(auix[:entity] || %{}, field.key))
    |> assign(:file_info, get_in(auix, [:upload_file_info, field.key]))
    |> assign(:downloadable?, get_in(auix, [:upload_downloadable, field.key]) || false)
  end

  @spec file_name(map() | nil, map()) :: binary()
  defp file_name(%{name: name}, _field) when is_binary(name) and name != "", do: name
  defp file_name(_file_info, field), do: dt(field.label)

  @spec file_meta(map() | nil) :: binary() | nil
  defp file_meta(file_info) when is_map(file_info) do
    parts =
      Enum.reject(
        [file_type(Map.get(file_info, :content_type)), file_size(Map.get(file_info, :size))],
        &is_nil/1
      )

    if parts == [], do: nil, else: Enum.join(parts, " · ")
  end

  defp file_meta(_file_info), do: nil

  @spec file_type(binary() | nil) :: binary() | nil
  defp file_type(content_type) when is_binary(content_type) and content_type != "" do
    content_type
    |> String.split("/")
    |> List.last()
    |> String.upcase()
  end

  defp file_type(_content_type), do: nil

  @spec file_size(non_neg_integer() | nil) :: binary() | nil
  defp file_size(size) when is_integer(size) and size < @kilobyte, do: "#{size} #{dt("bytes")}"

  defp file_size(size) when is_integer(size) and size < @megabyte,
    do: "#{Float.round(size / @kilobyte, 1)} KB"

  defp file_size(size) when is_integer(size), do: "#{Float.round(size / @megabyte, 1)} MB"
  defp file_size(_size), do: nil

  @spec accept_hint(binary() | :any) :: binary() | nil
  defp accept_hint(accept) when is_binary(accept) and accept != "" do
    accept
    |> String.split(",", trim: true)
    |> Enum.map_join(", ", fn
      "." <> extension -> String.upcase(extension)
      type -> type
    end)
  end

  defp accept_hint(_accept), do: nil
end
