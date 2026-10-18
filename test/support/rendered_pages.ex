defmodule Aurora.UixWeb.Test.RenderedPages do
  @moduledoc """
  Renders every CRUD page of the test app and keeps one normalized HTML file per page under
  `test/rendered_pages/`, so a change in the generated markup shows up as a diff.

  ## Key Features
  - Discovers the pages from the test router: every live route whose view module is loaded, for
    the `:index`, `:new`, `:edit`, `:show` and `:show_edit` actions.
  - Seeds one fixed data set through `Aurora.Uix.Test.Helper`, with `:rand` seeded, so the
    rendered values do not change between runs.
  - Takes the record id for the `:id` pages from the first show link of the index page, which
    works the same for both backends.
  - Normalizes only what changes on every run: UUIDs, timestamps, CSRF and LiveView session
    tokens, `phx-*` ids, the counter-based `auix-field-*` ids and the time-based group, sections
    and tab ids.

  ## Key Constraints
  - Must run inside the full `mix test` load (for example `mix test --only rendered_pages`):
    the routed view modules are defined by the `test/cases_live` and `test/browser_cases` files.
  - Pages are rendered with `Phoenix.LiveViewTest`, inside the caller's SQL sandbox.
  """

  import Phoenix.LiveViewTest

  alias Aurora.Uix.Test.Helper
  alias Aurora.UixWeb.Test.Router

  @endpoint Aurora.UixWeb.Test.Endpoint
  @root_dir "test/rendered_pages"
  @actions [:index, :new, :edit, :show, :show_edit]
  @action_files %{
    index: "index",
    new: "new",
    edit: "edit",
    show: "show",
    show_edit: "show-edit"
  }

  @typedoc "One page of the test app: its file name and how to reach it."
  @type page :: %{file: binary(), base: binary(), action: atom(), path: binary()}

  @doc """
  Returns the directory holding the committed rendered pages.
  """
  @spec root_dir() :: binary()
  def root_dir, do: @root_dir

  @doc """
  Seeds the fixed data set every page is rendered against.

  Deletes all sample data first, then creates a few records for every guide schema.
  """
  @spec seed() :: :ok
  def seed do
    :rand.seed(:exsss, {438, 438, 438})
    Helper.delete_all_sample_data()

    locations = Helper.create_sample_product_locations(2, :rendered)
    location_id = locations |> Map.fetch!("id_1") |> Map.fetch!(:id)

    Helper.create_sample_products_with_transactions(3, 2, :rendered, %{
      product_location_id: location_id
    })

    Helper.create_sample_products_with_suppliers(2, 2)
    Helper.create_sample_products_with_barcodes(2)
    Helper.create_sample_users(2)

    categories = Helper.create_sample_categories(2)
    authors = Helper.create_sample_authors(2)

    Enum.each(1..2, fn index ->
      Helper.create_sample_posts(1, %{
        title: "Rendered post #{index}",
        content: "Rendered content #{index}",
        author_id: Enum.at(authors, index - 1).id,
        category_id: Enum.at(categories, index - 1).id
      })
    end)

    Helper.create_sample_posts_with_topics(2, 2)
    Helper.create_sample_authors_with_profiles(2)
    :ok
  end

  @doc """
  Lists the pages to render, grouped by their index path and sorted by file name.
  """
  @spec pages() :: [page()]
  def pages do
    Router
    |> Phoenix.Router.routes()
    |> Enum.flat_map(&to_page/1)
    |> Enum.uniq_by(& &1.file)
    |> Enum.sort_by(& &1.file)
  end

  @doc """
  Renders every page with `conn` and returns `{file, normalized_html}` pairs.

  A page with an `:id` segment is rendered against the first record listed on its index page;
  when the index lists no record, the page is recorded as such instead of being rendered.
  """
  @spec render_all(Plug.Conn.t()) :: [{binary(), binary()}]
  def render_all(conn) do
    pages()
    |> Enum.group_by(& &1.base)
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.flat_map(fn {base, base_pages} -> render_base(conn, base, base_pages) end)
  end

  @doc """
  Normalizes rendered HTML so that only the generated UI is compared.

  Puts every tag on its own line, so a change shows as a line diff.
  """
  @spec normalize(binary()) :: binary()
  def normalize(html) do
    html
    |> replace_numbered(~r/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/, "uuid")
    |> String.replace(
      ~r/\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}(:\d{2}(\.\d+)?)?(Z|[+-]\d{2}:?\d{2})?/,
      "<datetime>"
    )
    |> String.replace(~r/(data-phx-(?:session|static))="[^"]*"/, "\\1=\"<token>\"")
    |> String.replace(~r/(name="_csrf_token"[^>]*value=)"[^"]*"/, "\\1\"<token>\"")
    |> String.replace(~r/(name="csrf-token"[^>]*content=)"[^"]*"/, "\\1\"<token>\"")
    |> String.replace(~r/phx-F[A-Za-z0-9_-]+/, "phx-<id>")
    |> String.replace(~r/(auix-field-(?:[a-z0-9_]+-){1,2})\d+/, "\\1<n>")
    |> String.replace(~r/-[0-9a-f]{8}\d+(?=["\-\s#])/, "-<titled-id>")
    |> String.replace(~r/>\s*</, ">\n<")
    |> String.trim()
    |> Kernel.<>("\n")
  end

  @doc """
  Writes the rendered pages under `root_dir/0`, replacing whatever is there.
  """
  @spec write_all([{binary(), binary()}]) :: :ok
  def write_all(rendered) do
    File.rm_rf!(@root_dir)

    Enum.each(rendered, fn {file, html} ->
      path = Path.join(@root_dir, file)
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, html)
    end)
  end

  @doc """
  Compares the rendered pages with the committed ones.

  Returns a list of human-readable differences: missing, unexpected and changed pages, each
  changed page with the lines that differ.
  """
  @spec differences([{binary(), binary()}]) :: [binary()]
  def differences(rendered) do
    rendered_files = Map.new(rendered)

    committed_files =
      @root_dir
      |> Path.join("**/*.html")
      |> Path.wildcard()
      |> Enum.map(&Path.relative_to(&1, @root_dir))

    missing =
      committed_files
      |> Enum.reject(&Map.has_key?(rendered_files, &1))
      |> Enum.map(&"#{&1}: committed but no longer rendered")

    changed =
      rendered
      |> Enum.flat_map(fn {file, html} ->
        case File.read(Path.join(@root_dir, file)) do
          {:ok, ^html} -> []
          {:ok, committed} -> ["#{file}: changed\n#{line_diff(committed, html)}"]
          {:error, :enoent} -> ["#{file}: rendered but not committed"]
        end
      end)

    missing ++ changed
  end

  ## PRIVATE

  @spec to_page(map()) :: [page()]
  defp to_page(%{path: path, metadata: %{phoenix_live_view: {module, action, _, _}}})
       when action in @actions do
    path = String.replace(path, ~r"/+", "/")
    base = if action == :index, do: path, else: String.replace(path, ~r"/(new|:id/[a-z-]+)$", "")

    if Code.ensure_loaded?(module) do
      file = String.trim_leading(base, "/") <> "/" <> Map.fetch!(@action_files, action) <> ".html"
      [%{file: file, base: base, action: action, path: path}]
    else
      []
    end
  end

  defp to_page(_route), do: []

  @spec render_base(Plug.Conn.t(), binary(), [page()]) :: [{binary(), binary()}]
  defp render_base(conn, base, base_pages) do
    record_id = first_record_id(conn, base)
    Enum.map(base_pages, &{&1.file, render_page(conn, &1, record_id)})
  end

  @spec first_record_id(Plug.Conn.t(), binary()) :: binary() | nil
  defp first_record_id(conn, base) do
    with {:ok, html} <- live_html(conn, base),
         [_, id] <- Regex.run(~r/href="#{Regex.escape(base)}\/([^"\/]+)\/show"/, html) do
      id
    else
      _ -> nil
    end
  end

  @spec render_page(Plug.Conn.t(), page(), binary() | nil) :: binary()
  defp render_page(conn, %{path: path}, record_id) do
    cond do
      not String.contains?(path, ":id") -> render_path(conn, path)
      is_nil(record_id) -> "<!-- no record listed on the index page -->\n"
      true -> render_path(conn, String.replace(path, ":id", record_id))
    end
  end

  @spec render_path(Plug.Conn.t(), binary()) :: binary()
  defp render_path(conn, path) do
    case live_html(conn, path) do
      {:ok, html} -> normalize(html)
      {:error, reason} -> "<!-- not rendered: #{inspect(reason)} -->\n" |> normalize()
    end
  end

  @spec live_html(Plug.Conn.t(), binary()) :: {:ok, binary()} | {:error, term()}
  defp live_html(conn, path) do
    case live(conn, path) do
      {:ok, view, _html} -> {:ok, render(view)}
      {:error, {kind, %{to: to}}} -> {:error, {kind, to}}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec replace_numbered(binary(), Regex.t(), binary()) :: binary()
  defp replace_numbered(html, regex, label) do
    numbers =
      regex
      |> Regex.scan(html)
      |> List.flatten()
      |> Enum.uniq()
      |> Enum.with_index(1)
      |> Map.new()

    Regex.replace(regex, html, &"#{label}-#{Map.fetch!(numbers, &1)}")
  end

  @spec line_diff(binary(), binary()) :: binary()
  defp line_diff(committed, rendered) do
    committed
    |> String.split("\n")
    |> List.myers_difference(String.split(rendered, "\n"))
    |> Enum.flat_map(fn
      {:eq, _lines} -> []
      {:del, lines} -> Enum.map(lines, &"  - #{&1}")
      {:ins, lines} -> Enum.map(lines, &"  + #{&1}")
    end)
    |> Enum.take(40)
    |> Enum.join("\n")
  end
end
