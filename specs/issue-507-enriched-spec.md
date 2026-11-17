<!-- enriched-spec:start v2 -->
## Enriched Spec

**Complexity:** normal

### Overview
Every default button and link action gets an icon. Below the 640px breakpoint a default action button shows only that icon and keeps its label as `title` and `aria-label`; from 641px up nothing changes. The new `action_icons:` option changes the icon of a default action by name on `index_columns`, `edit_layout` and `show_layout`, and on one-to-many and embeds-many fields. The change is UI-only: it consumes layout options, so Ash and Ecto (`ctx`) resources behave the same.

### Section Map
| ID | Type | Scope | Depends on | Branch | PR title |
|---|---|---|---|---|---|
| DOC-1 | Documentation | CHANGELOG.md § [0.2.1] › Added · guides/core/layouts.md § Index / Form / Show Layout Options, § Field-Level Options · guides/customization/custom_actions.md § Action Icons (new) · guides/customization/styling.md § Class reference | none | federico/507-doc-1-action-icons | docs: action icons and icon-only mobile actions (#507 · DOC-1) |
| UI-1 | UI | layout options + components + theme · index default actions, `action_icons:` on `index_columns` | DOC-1 | federico/507-ui-1-index-action-icons | feat: index action icons and icon-only mobile buttons (#507 · UI-1) |
| UI-2 | UI | form + show default actions, `action_icons:` on `edit_layout` and `show_layout` | UI-1 | federico/507-ui-2-form-show-action-icons | feat: form and show action icons (#507 · UI-2) |
| UI-3 | UI | one-to-many + embeds-many default actions, `action_icons:` field option | UI-1 | federico/507-ui-3-field-action-icons | feat: one-to-many and embeds-many action icons (#507 · UI-3) |

A section starts only when every dependency is **merged**. Independent
sections may run in parallel. Status is derived from GitHub, never recorded
here.

<!-- section:DOC-1:start -->
### DOC-1 — Documentation
Depends on: none

#### Documentation references
- `CHANGELOG.md` § `## [0.2.1]` › `### Added`
- `guides/core/layouts.md` § Index Layout Options, § Form Layout Options, § Show Layout Options, § Field-Level Options
- `guides/customization/custom_actions.md` § Configuring Actions via Layout DSL, § Action Handlers, § Association Actions
- `guides/customization/styling.md` § Class reference

#### Implementation details

##### CHANGELOG.md
1. § `## [0.2.1]` › `### Added` — insert verbatim after the line `  - New guide: Reusable Components.` and before the blank line that precedes `### Changed`:
   ```
   - **Action icons**
     - Every default action that renders a button or a link has an icon. Below the 640px breakpoint a
       default action button shows only its icon, with its label as `title` and `aria-label`; from 641px
       up nothing changes. Delete selected keeps its count badge.
     - `action_icons:` on `index_columns`, `edit_layout` and `show_layout`, and on one-to-many and
       embeds-many fields, changes the icon of a default action by name. An icon is a Heroicon name, an
       image URL, a character, or a named function of the action's assigns returning one of those. An
       unknown key fails compilation and lists the valid keys.
     - The row actions (show, edit, delete) take their icons from `action_icons:` too.
     - `<.action_content>` and `<.action_icon>` in the core components let a custom action follow the
       same breakpoint.
     - New theme classes `auix-action-icon`, `auix-action-label`, `auix-action-icon-image` and
       `auix-action-icon-text`: re-run `mix auix.gen.stylesheet` after upgrading.
   ```

##### guides/core/layouts.md
1. § Index Layout Options — insert verbatim on the line after the bullet ``- `:new_action_label` — Label for the "new" action button (default: `"New {name}"`)``:
   ```
   - `:action_icons` — The icons of the default actions, by action name, such as `[default_new: "hero-sparkles"]`. Below the 640px breakpoint a default action button shows only its icon (see [Custom Actions › Action Icons](../customization/custom_actions.md#action-icons))
   ```
2. § Form Layout Options — insert verbatim on the line after the bullet ``- `:save_action_label` — Label for the save action button (default: `"Save {name}"`)``:
   ```
   - `:action_icons` — The icon of the save action, such as `[default_save: "hero-check"]` (see [Custom Actions › Action Icons](../customization/custom_actions.md#action-icons))
   ```
3. § Show Layout Options — insert verbatim on the line after the bullet ``- `:back_action_label` — Label for the back action (default: `"Back to {title}"`)``:
   ```
   - `:action_icons` — The icons of the edit and back actions, such as `[default_back: "←"]` (see [Custom Actions › Action Icons](../customization/custom_actions.md#action-icons))
   ```
4. § Field-Level Options › **Relevant Field Options:** — insert verbatim on the line after the bullet ``- `:option_label` — For select/radio fields``:
   ```
   - `:action_icons` — For one-to-many and embeds-many fields: the icons of the field's default actions (see [Custom Actions › Action Icons](../customization/custom_actions.md#action-icons))
   ```

##### guides/customization/custom_actions.md
1. New section `## Action Icons` — insert verbatim after the paragraph that ends ``see [Layout System → Actions: Customizing Buttons & Links](../core/layouts.md#actions-customizing-buttons--links).`` and before the heading `## Action Handlers`:
   ````
   ## Action Icons

   Every default action that renders a button or a link has an icon. Below the `sm` breakpoint
   (640px wide) a default action button shows only its icon; its label stays on the button as
   `title` and `aria-label`. From 641px up nothing changes: a text button shows its label, and an
   icon action, such as a row action, shows its icon.

   `action_icons:` changes the icon of a default action. The action keeps its function component,
   its events and its label. The keys are the default action names of the layout:

   ```elixir
   index_columns :product, [:name],
     action_icons: [default_new: :"hero-sparkles", default_selected_delete_all: "hero-archive-box-x-mark"]

   edit_layout :product, action_icons: [default_save: "hero-check"] do
     stacked [:reference, :name]
   end

   show_layout :product, action_icons: [default_back: "←"] do
     stacked [:reference, :name]
   end
   ```

   An icon is told apart by its value:

   | Value | Renders |
   |---|---|
   | an atom such as `:"hero-sparkles"`, a string starting with `hero-` | the Heroicon of that name |
   | a string starting with `/` or `http` | an image with that URL |
   | any other string, such as `"←"` | the text itself |
   | a named function of arity 1, such as `&MyAppWeb.Icons.new_icon/1` | the icon it returns for the action's assigns |

   The keys and their default icons:

   | Layout | Key | Default icon |
   |---|---|---|
   | `index_columns` | `:default_row_show` | `hero-eye` |
   | `index_columns` | `:default_row_edit` | `hero-pencil` |
   | `index_columns` | `:default_row_delete` | `hero-trash` |
   | `index_columns` | `:default_selected_uncheck_all` | `hero-x-circle` |
   | `index_columns` | `:default_selected_delete_all` | `hero-trash` |
   | `index_columns` | `:default_selected_check_all` | `hero-check-circle` |
   | `index_columns` | `:default_toggle_filters` | `hero-funnel` |
   | `index_columns` | `:default_clear` | `hero-x-mark` |
   | `index_columns` | `:default_submit` | `hero-magnifying-glass` |
   | `index_columns` | `:default_new` | `hero-plus` |
   | `edit_layout` | `:default_save` | `hero-check` |
   | `show_layout` | `:default_edit` | `hero-pencil` |
   | `show_layout` | `:default_back` | `hero-arrow-left` |
   | one-to-many field | `:default_new` | `hero-plus` |
   | one-to-many field | `:default_row_show` | `hero-eye` |
   | one-to-many field | `:default_row_edit` | `hero-pencil` |
   | one-to-many field | `:default_row_delete` | `hero-trash` |
   | embeds-many field | `:default_header_enable_add_entry` | `hero-plus` |
   | embeds-many field | `:default_footer_enable_add_entry` | `hero-plus` |
   | embeds-many field | `:default_add_entry` | `hero-plus` |
   | embeds-many field | `:default_remove_entry` | `hero-trash` |

   `:default_toggle_all_selected`, `:default_sort` and `:default_pagination` are not keys: they
   render a checkbox, a select and a pager. Many-to-many and multi-select fields have no keys: their
   only default action is the `:default_toggle_all` checkbox. An unknown key fails compilation, and
   the error lists the valid keys of the layout. **Delete selected** keeps its count badge when only
   its icon shows.

   One-to-many and embeds-many fields take `action_icons:` in their field options, next to the
   action operations of [Association Actions](#association-actions):

   ```elixir
   edit_layout :product do
     stacked([
       :name,
       product_transactions: [action_icons: [default_new: "hero-sparkles"]]
     ])
   end
   ```

   ### Custom actions on mobile

   Aurora UIX cannot know the names of your custom actions, so it resolves no icon for them and
   their markup stays the same at every width. To make a custom button follow the breakpoint, render
   its content with `<.action_content>` from the core components, and put its label on the button as
   `title` and `aria-label`:

   ```elixir
   defmodule MyAppWeb.ProductActions do
     use Aurora.Uix.CoreComponentsImporter

     def archive_action(assigns) do
       ~H"""
       <.button type="button" phx-click="archive" title="Archive" aria-label="Archive">
         <.action_content icon="hero-archive-box" label="Archive" />
       </.button>
       """
     end
   end
   ```

   `<.action_content>` shows its `label` from 641px up and its `icon` below. With
   `icon_always?={true}` it shows the icon at every width and hides only the label below the
   breakpoint. `<.action_icon icon={...} />` renders an icon value alone, as the table above reads it.
   ````

##### guides/customization/styling.md
1. § Class reference — insert verbatim on the lines after the table row that starts ``| `.auix-index-sort-action` |``:
   ```
   | `.auix-action-icon` | Icon of a default action button (`<.action_content>`); hidden from the `sm` breakpoint up, shown below it | Structural only |
   | `.auix-action-label` | Label of a default action button (`<.action_content>`); hidden below the `sm` breakpoint | Structural only |
   | `.auix-action-icon-image` | An action icon given as an image URL (`<.action_icon>`) | Structural only |
   | `.auix-action-icon-text` | An action icon given as a character (`<.action_icon>`) | Structural only |
   ```

##### Acceptance criteria
- [x] AC-1: the CHANGELOG entry sits under the current unreleased version and carries no
      issue-link suffix (mechanical — no red test; verified by
      `git diff origin/main...HEAD -- CHANGELOG.md | grep -E '^\+.*\[#[0-9]+\]'` returning nothing)
- [x] AC-2: no file outside the documentation set modified, apart from this issue's spec file
      (its AC ticks) (mechanical — no red test; verified by
      `git diff --name-only origin/main...HEAD` listing only `CHANGELOG.md`, `README.md`,
      `CONTRIBUTING.md`, `ROADMAP.md`, `guides/**/*.md` and `specs/issue-507-enriched-spec.md`)
- [x] AC-3: `guides/customization/custom_actions.md § Action Icons` reads as prescribed, between
      § Configuring Actions via Layout DSL and § Action Handlers (mechanical — no red test; verified by
      `grep -n -E '^## (Configuring Actions via Layout DSL|Action Icons|Action Handlers)$' guides/customization/custom_actions.md`
      printing the three headings in that order, and `grep -c 'default_remove_entry' guides/customization/custom_actions.md` printing `1`)
- [x] AC-4: `guides/core/layouts.md` documents `:action_icons` in § Index Layout Options, § Form Layout
      Options, § Show Layout Options and § Field-Level Options (mechanical — no red test; verified by
      `grep -c '^- `:action_icons`' guides/core/layouts.md` printing `4`)
- [x] AC-5: `guides/customization/styling.md § Class reference` lists the four new classes
      (mechanical — no red test; verified by
      `grep -c -E '^\| `\.auix-action-(icon|label|icon-image|icon-text)`' guides/customization/styling.md` printing `4`)

##### Green checks
1. `mix consistency` clean (code-issue); `mix test` — full suite green
   (review-issue runs the suite)
<!-- section:DOC-1:end -->
<!-- section:UI-1:start -->
### UI-1 — UI · action icon foundation and index default actions
Depends on: DOC-1

#### Documentation references
- `guides/customization/custom_actions.md` § Action Icons (written by DOC-1)
- `guides/core/layouts.md` § Index Layout Options
- `guides/customization/styling.md` § Class reference

Layout types: `:index` only. `:form` and `:show` belong to UI-2; one-to-many and embeds-many fields belong to UI-3. Backend-agnostic: no file under `lib/aurora_uix/integration/` changes.

#### Implementation details
1. `lib/aurora_uix/action.ex` — modified.
   a. Insert after the closing `}` of the `@actions %{…}` attribute, before `@doc """` of `new/2`:
      ```elixir
      # The default icon of each default action that renders a button or a link. A key here is a
      # valid `action_icons:` key of its group; a group without keys has no entry.
      @default_icons %{
        index: [
          default_row_show: "hero-eye",
          default_row_edit: "hero-pencil",
          default_row_delete: "hero-trash",
          default_selected_uncheck_all: "hero-x-circle",
          default_selected_delete_all: "hero-trash",
          default_selected_check_all: "hero-check-circle",
          default_toggle_filters: "hero-funnel",
          default_clear: "hero-x-mark",
          default_submit: "hero-magnifying-glass",
          default_new: "hero-plus"
        ],
        form: [default_save: "hero-check"],
        show: [default_edit: "hero-pencil", default_back: "hero-arrow-left"],
        one_to_many: [
          default_new: "hero-plus",
          default_row_show: "hero-eye",
          default_row_edit: "hero-pencil",
          default_row_delete: "hero-trash"
        ],
        embeds_many: [
          default_header_enable_add_entry: "hero-plus",
          default_footer_enable_add_entry: "hero-plus",
          default_add_entry: "hero-plus",
          default_remove_entry: "hero-trash"
        ]
      }

      @icon_type {:or, [:atom, :string, {:fun, 1}]}
      ```
   b. Insert after `def available_actions(action_group), do: Map.get(@actions, action_group)` (new; `rg -n 'default_icons|icons_schema|default_icon' lib` returns nothing):
      ```elixir
      @doc """
      Retrieves the default icons of an action group.

      ## Parameters
      - `action_group` (atom()) - The group, such as `:index` or `:embeds_many`.

      ## Returns
      `keyword()` - The default icon of each default action of the group that renders a button or a
      link, by action name. `[]` for a group without one, such as `:many_to_many`.
      """
      @spec default_icons(atom()) :: keyword()
      def default_icons(action_group), do: Map.get(@default_icons, action_group, [])

      @doc """
      Retrieves the default icon of one default action.

      ## Parameters
      - `action_group` (atom()) - The group, such as `:index`.
      - `action_name` (atom()) - The default action, such as `:default_new`.

      ## Returns
      `binary()` - A `hero-*` icon name. Raises `KeyError` for an action without a default icon.
      """
      @spec default_icon(atom(), atom()) :: binary()
      def default_icon(action_group, action_name),
        do: action_group |> default_icons() |> Keyword.fetch!(action_name)

      @doc """
      Retrieves the `Spark.Options` schema of a group's `action_icons:` keys.

      ## Parameters
      - `action_group` (atom()) - The group, such as `:index`.

      ## Returns
      `keyword()` - One entry per key of `default_icons/1`. A value is a hero icon name (atom,
      `"hero-*"` string), an image URL, a character, a function of arity 1 receiving the action's
      assigns.
      """
      @spec icons_schema(atom()) :: keyword()
      def icons_schema(action_group) do
        action_group
        |> default_icons()
        |> Enum.map(fn {action_name, _icon} -> {action_name, [type: @icon_type]} end)
      end
      ```
   c. `@moduledoc` › `## Key Features` — append the bullet:
      `* Holds the default icon of each default action that renders a button or a link (`default_icons/1`) and the schema of the `action_icons:` layout option (`icons_schema/1`).`
2. `lib/aurora_uix/templates/basic/actions.ex` — modified. Insert before `## PRIVATE` (new; `rg -n 'def icon\(|label_title' lib/aurora_uix/templates/basic/actions.ex` returns nothing):
   ```elixir
   @doc """
   Resolves the icon of a default action.

   ## Parameters
   - `assigns` (map()) - The assigns the action renders with; a function icon receives them.
   - `icons` (keyword()) - The `action_icons:` entries that apply, by action name.
   - `action_group` (atom()) - The group of the action, such as `:index`.
   - `action_name` (atom()) - The default action, such as `:default_new`.

   ## Returns
   `atom() | binary()` - The entry of `icons`, the result of a function entry, else the default
   icon of `Aurora.Uix.Action.default_icon/2`.
   """
   @spec icon(map(), keyword(), atom(), atom()) :: atom() | binary()
   def icon(assigns, icons, action_group, action_name) do
     case Keyword.get(icons, action_name) do
       nil -> Action.default_icon(action_group, action_name)
       icon when is_function(icon, 1) -> icon.(assigns)
       icon -> icon
     end
   end

   @doc """
   Returns the text a default action puts in its `title` and `aria-label`.

   ## Parameters
   - `label` (term()) - The action's label: a binary, an atom, `nil`, a rendered template.

   ## Returns
   `binary() | nil` - The label as text; `nil` for `nil` and for a rendered template, so the
   attributes are left out.
   """
   @spec label_title(term()) :: binary() | nil
   def label_title(nil), do: nil
   def label_title(label) when is_binary(label), do: label
   def label_title(label) when is_atom(label), do: Atom.to_string(label)
   def label_title(_label), do: nil
   ```
3. `lib/aurora_uix/layout/options/index.ex` — modified.
   a. Insert `alias Aurora.Uix.Action` on the line before `alias Aurora.Uix.Layout.Options, as: LayoutOptions`.
   b. Insert after the line `@label {:or, [nil, :string, :atom, {:fun, 0}, {:fun, 1}]}`:
      ```elixir
      @action_icons {:keyword_list, Action.icons_schema(:index)}
      ```
   c. Insert `option(:action_icons, @action_icons)` on the line after `option(:alternate_streams_suffixes, {:or, [{:list, :string}, {:fun, 1}]})`.
   d. Insert on the line before `defp get_default(_assigns, option), do: {:not_found, option}`:
      ```elixir
      defp get_default(%{auix: %{layout_type: :index}}, :action_icons), do: {:ok, []}
      ```
   e. `@moduledoc` › `## Options` — insert after the `:new_action_label` bullet and its two sub-bullets:
      ```
      * `:action_icons` - The icons of the default actions, by action name. Below the `sm`
        breakpoint a default action button shows only its icon.
        - Accepts a keyword list. A key is a default action that renders a button or a link (see
          `Aurora.Uix.Action.default_icons/1`); an unknown key fails compilation. A value is a hero
          icon name (atom, `"hero-*"` string), an image URL (`"/…"`, `"http…"`), a character, a named
          function of arity 1 receiving the action's assigns.
        - Default: `[]` (every action keeps its default icon).
      ```
   The layout DSL needs no change: `container_opts/2` in `lib/aurora_uix/layout/create_ui/dsl.ex` accepts every name of `Options.available_options(:index)` and `validate_option_types/2` validates `action_icons:` against the declared `{:keyword_list, …}` type, which rejects an unknown key with `index layout: unknown options [<key>], valid options are: [<keys>] (in options [:action_icons])`.
4. `lib/aurora_uix/templates/basic/components/core_components.ex` — modified. Insert after the line `resolve_component_for(:icon)` and before `## JS Commands` (new; `rg -n 'action_icon|action_content' lib` returns nothing):
   ```elixir
   @doc """
   Renders the icon of an action.

   The icon is told apart by its text: a name starting with `hero-` is a
   [Heroicon](https://heroicons.com), a text starting with `/` or `http` is an image URL, and any
   other text, such as `"←"`, is shown as it is. An atom is read as its text.

   ## Examples

       <.action_icon icon="hero-plus" class="auix-icon-size-button" />
       <.action_icon icon="/images/archive.svg" class="auix-icon-size-5" />
       <.action_icon icon="←" />
   """
   attr(:icon, :any, required: true, doc: "a hero icon name (atom, string), an image URL, a character")
   attr(:class, :string, default: nil, doc: "classes added to the icon, such as its size")
   attr(:host_components, :any)

   @spec action_icon(map) :: Rendered.t()
   def action_icon(%{host_components: nil} = assigns) do
     icon = to_string(assigns.icon)
     assigns = assigns |> assign(:icon_text, icon) |> assign(:icon_kind, icon_kind(icon))

     ~H"""
     <.icon :if={@icon_kind == :hero} name={@icon_text} class={@class} />
     <img :if={@icon_kind == :url} src={@icon_text} alt="" class={["auix-action-icon-image", @class]} />
     <span :if={@icon_kind == :text} class={["auix-action-icon-text", @class]}>{@icon_text}</span>
     """
   end

   resolve_component_for(:action_icon)

   @doc """
   Renders the content of an action button: its icon and its label.

   From the `sm` breakpoint up the label shows and the icon hides; below it only the icon shows.
   With `icon_always?`, the icon shows at every width and only the label hides below the
   breakpoint. Put the label on the button as `title` and `aria-label` too, so it stays available
   when it hides.

   ## Examples

       <.button title="Archive" aria-label="Archive">
         <.action_content icon="hero-archive-box" label="Archive" />
       </.button>
   """
   attr(:icon, :any, required: true, doc: "the icon, as `action_icon/1` takes it")
   attr(:label, :any, required: true, doc: "the label")
   attr(:icon_always?, :boolean, default: false, doc: "shows the icon at every width")
   attr(:icon_class, :string, default: "auix-icon-size-button", doc: "classes added to the icon")
   attr(:host_components, :any)

   @spec action_content(map) :: Rendered.t()
   def action_content(%{host_components: nil} = assigns) do
     ~H"""
     <span :if={not @icon_always?} class="auix-action-icon"><.action_icon icon={@icon} class={@icon_class} /></span>
     <.action_icon :if={@icon_always?} icon={@icon} class={@icon_class} />
     <span class="auix-action-label">{@label}</span>
     """
   end

   resolve_component_for(:action_content)
   ```
   Insert after `defp maybe_log_copyable_warning(_assigns), do: :ok`, before the module's final `end`:
   ```elixir
   # How `action_icon/1` shows an icon: a Heroicon, an image, the text itself.
   @spec icon_kind(binary()) :: :hero | :url | :text
   defp icon_kind("hero-" <> _name), do: :hero
   defp icon_kind("/" <> _path), do: :url
   defp icon_kind("http" <> _url), do: :url
   defp icon_kind(_text), do: :text
   ```
5. `lib/aurora_uix/templates/basic/components/confirm_button.ex` — modified.
   a. `update/2`: insert `|> assign(:title, Map.get(assigns, :title))` on the line after `|> assign(:class, Map.get(assigns, :class, "auix-confirm-button--show-action"))`.
   b. `render/1`: replace `<.button type={@type} class={@class} phx-click="show-modal" phx-target={@myself}>` with `<.button type={@type} class={@class} phx-click="show-modal" phx-target={@myself} title={@title} aria-label={@title}>`.
   c. `@moduledoc` › `## Optional Assigns` — insert after the `:target` bullet:
      ``* `:title` - Text for the main button's `title` and `aria-label` (defaults to `nil`: no attribute)``
6. `lib/aurora_uix/templates/basic/themes/base.ex` — modified. Insert after the `rule(:auix_button__iconized, """…""")` call and before `rule(:auix_button_toggle_filters_container, """`:
   ```elixir
   rule(:auix_action_icon, """
   /* auix-action-icon */
   .auix-action-icon {
     display: none;
   }

   @media (max-width: #{breakpoint(:sm)}) {
     .auix-action-icon {
       display: inline-flex;
       align-items: center;
     }
   }
   """)

   rule(:auix_action_label, """
   /* auix-action-label */
   @media (max-width: #{breakpoint(:sm)}) {
     .auix-action-label {
       display: none;
     }
   }
   """)

   rule(:auix_action_icon_image, """
   /* auix-action-icon-image */
   .auix-action-icon-image {
     display: inline-block;
     vertical-align: middle;
     object-fit: contain;
   }
   """)

   rule(:auix_action_icon_text, """
   /* auix-action-icon-text */
   .auix-action-icon-text {
     display: inline-flex;
     align-items: center;
     justify-content: center;
     line-height: 1;
   }
   """)
   ```
7. `lib/aurora_uix/templates/basic/actions/index.ex` — modified.
   a. `## PRIVATE` — insert after `defp add_default_footer_actions(socket), …` and before `# The id comes from the same :row_id function that renders the row.`:
      ```elixir
      # The icon of an index default action: the layout's `action_icons:` entry, else its default.
      @spec resolve_icon(map(), atom()) :: atom() | binary()
      defp resolve_icon(assigns, action_name),
        do: Actions.icon(assigns, assigns.auix.layout_options.action_icons, :index, action_name)

      # Puts the icon, the label and the title of an index default action in the assigns.
      @spec put_action(map(), atom(), term()) :: map()
      defp put_action(assigns, action_name, label) do
        assigns
        |> Map.put(:icon, resolve_icon(assigns, action_name))
        |> Map.put(:label, label)
        |> Map.put(:title, Actions.label_title(label))
      end
      ```
   b. Row actions — in each listed clause, insert the first line before `~H"""` and replace the icon line:

      | Function | Clauses | First line | Replace | With |
      |---|---|---|---|---|
      | `show_row_action/1` | both | `assigns = Map.put(assigns, :icon, resolve_icon(assigns, :default_row_show))` | `<.icon class="auix-icon-size-5 auix-icon-info" name="hero-eye" />` | `<.action_icon icon={@icon} class="auix-icon-size-5 auix-icon-info" />` |
      | `edit_row_action/1` | both | `assigns = Map.put(assigns, :icon, resolve_icon(assigns, :default_row_edit))` | `<.icon class="auix-icon-size-5 auix-icon-safe" name="hero-pencil" />` | `<.action_icon icon={@icon} class="auix-icon-size-5 auix-icon-safe" />` |
      | `remove_row_action/1` | the one clause | `assigns = Map.put(assigns, :icon, resolve_icon(assigns, :default_row_delete))` | `<.icon class="auix-icon-size-5 auix-icon-danger" name="hero-trash" />` | `<.action_icon icon={@icon} class="auix-icon-size-5 auix-icon-danger" />` |
   c. `selected_delete_all_action/1`, the guarded clause — replace the body with:
      ```elixir
      assigns =
        assigns
        |> Map.put(:selected_button_class, @selected_button_class)
        |> put_action(:default_selected_delete_all, dt("Delete selected"))

      ~H"""
        <.live_component 
          id={BasicHelpers.instance_dom_id(@auix, "auix-delete-all-button")}
          module={ConfirmButton}
          class={@selected_button_class}
          title={@title}
          value={%{delete_all: true}}
          event="selected-delete_all"
          target={uix_id_selector(@auix.index_form_id)}
        >
          <:content>
            <.action_content icon={@icon} label={@label} /> <span class="auix-button-badge">{@auix.selection.selected_count}</span>
          </:content>

          <:confirm_message>
            <div>
              <%= if @auix.selection.selected_count == 1 do %>
                <span>{dt("Do you want to remove the selected item?")}</span>
              <% else %>
                <span>{dt("Do you want to remove all the selected items?")}</span>
              <% end %>
            </div>
          </:confirm_message>
          
        </.live_component>
      """
      ```
   d. `selected_uncheck_all_action/1`:
      - the clause guarded `when toggle_all_mode == :none and selected_count > 0` — replace the body with:
        ```elixir
        assigns =
          assigns
          |> Map.put(:selected_button_class, @selected_button_class)
          |> put_action(:default_selected_uncheck_all, dt("Uncheck all"))

        ~H"""
        <.button type="button" class={@selected_button_class} phx-click="selected-toggle_all" phx-value-state="false" phx-target={@auix[:_myself]}
            name={"auix-selected-uncheck_all-#{@auix.module}"} title={@title} aria-label={@title}>
          <.action_content icon={@icon} label={@label} />
        </.button>
        """
        ```
      - the clause guarded `when toggle_all_mode == :uncheck` — replace the body with:
        ```elixir
        assigns =
          assigns
          |> Map.put(:selected_button_class, @selected_button_class)
          |> put_action(
            :default_selected_uncheck_all,
            dt("De-selecting all items. Selection is disabled for a while... Click to cancel")
          )

        ~H"""
        <.button type="button" class={@selected_button_class} phx-click="selected-cancel_toggle_all" phx-target={@auix[:_myself]} title={@title} aria-label={@title}><.action_content icon={@icon} label={@label} /></.button>
        """
        ```
   e. `selected_check_all_action/1`:
      - the clause guarded `when toggle_all_mode == :none and selected_count < entries_count` — replace the body with:
        ```elixir
        assigns =
          assigns
          |> Map.put(:selected_button_class, @selected_button_class)
          |> put_action(:default_selected_check_all, dt("Check all"))

        ~H"""
        <.button type="button" class={@selected_button_class} phx-click="selected-toggle_all" phx-value-state="true" phx-target={@auix[:_myself]}
            name={"auix-selected_check_all-#{@auix.module}"} disabled={@auix.selection.toggle_all_mode != :none} title={@title} aria-label={@title}>
          <.action_content icon={@icon} label={@label} />
        </.button>
        """
        ```
      - the clause guarded `when toggle_all_mode == :check` — replace the body with:
        ```elixir
        assigns =
          assigns
          |> Map.put(:selected_button_class, @selected_button_class)
          |> put_action(
            :default_selected_check_all,
            dt("Selecting all items. Selection is disabled for a while... Click to cancel")
          )

        ~H"""
        <.button type="button" class={@selected_button_class} phx-click="selected-cancel_toggle_all" phx-target={@auix[:_myself]} title={@title} aria-label={@title}><.action_content icon={@icon} label={@label} /></.button>
        """
        ```
   f. `new_header_action/1` — in both clauses, insert before `~H"""`:
      ```elixir
      assigns = put_action(assigns, :default_new, dt(assigns.auix.layout_options.new_action_label))
      ```
      and replace `<.button>{dt(@auix.layout_options.new_action_label)}</.button>` with `<.button><.action_content icon={@icon} label={@label} /></.button>`. On the `<.auix_link …>` opening tag of each clause, add `title={@title} aria-label={@title}` after `role="button"`.
   g. `toggle_filters_action/1` — insert before `~H"""`:
      ```elixir
      assigns = Map.put(assigns, :icon, resolve_icon(assigns, :default_toggle_filters))
      ```
      Replace `<.icon name="hero-funnel" class={if @auix.filters_selected_count > 0, do: "auix-icon-inactive auix-icon-size-5", else: "auix-icon-info auix-icon-size-5"}/>` with `<.action_icon icon={@icon} class={if @auix.filters_selected_count > 0, do: "auix-icon-inactive auix-icon-size-5", else: "auix-icon-info auix-icon-size-5"} />`. Replace `<a href="#" phx-click="filter-toggle" phx-target={@auix[:_myself]} name="auix-filter_toggle_open" class="hero-funnel auix-icon-info auix-icon-size-5" />` with `<a href="#" phx-click="filter-toggle" phx-target={@auix[:_myself]} name="auix-filter_toggle_open"><.action_icon icon={@icon} class="auix-icon-info auix-icon-size-5" /></a>`. The `hero-x-mark` close marker stays.
   h. `clear_filters_action/1`, the `filters_enabled?: true` clause — replace the body with:
      ```elixir
      assigns =
        assigns
        |> Map.put(:filters_button_class, @filters_button_class)
        |> put_action(:default_clear, dt("Clear Filters"))

      ~H"""
      <.button type="button" class={@filters_button_class} phx-click="filters-clear" phx-target={@auix[:_myself]} name={"auix-filters_clear-#{@auix.module}"} title={@title} aria-label={@title}><.action_content icon={@icon} label={@label} /></.button>
      """
      ```
   i. `submit_filters_action/1`, the `filters_enabled?: true` clause — replace the body with:
      ```elixir
      assigns =
        assigns
        |> Map.put(:filters_button_class, @filters_button_class)
        |> put_action(:default_submit, dt("Submit"))

      ~H"""
      <.button type="button" class={@filters_button_class} phx-click="filters-submit" phx-target={@auix[:_myself]} name={"auix-filters_submit-#{@auix.module}"} title={@title} aria-label={@title}><.action_content icon={@icon} label={@label} /></.button>
      """
      ```
   j. `toggle_selected_all_in_page_action/1`, `sort_header_action/1` and `pagination_action/1` stay unchanged: they are not `action_icons:` keys.
   k. `@moduledoc` › `## Key Features` — append the bullet:
      `- Every button and link action takes its icon from the layout's `action_icons:` option (defaults in `Aurora.Uix.Action.default_icons/1`); below the `sm` breakpoint a text button shows only its icon`
8. Markup changes (Writing rule 6). The selectors `a[name='auix-new-product']`, `[name='auix-filter_toggle_open']`, `#auix-delete-all-button-product>button`, `button[name='auix-selected_check_all-product']`, `button[name='auix-selected-uncheck_all-product']` and the label texts keep their values; a default hero icon adds no text. The tests that drive them keep their drive unchanged: `test/cases_live/selected_test.exs`, `test/cases_live/events_test.exs`, `test/cases_live/ash_events_test.exs`, `test/cases_live/create_ui_actions_index_test.exs`, and the `[name='auix-filter_toggle_open']` clicks in `test/cases_live/ash_default_layout_test.exs`, `sortable_columns_test.exs`, `special_fields_ui_test.exs`, `ash_where_filter_layout_test.exs`.
9. `test/support/app_web/routes.ex` — insert after the four-line `RoutesHelper.register_product_crud(` call whose arguments are `AssociationOne2ManyUIActionsTest,` and `"association-one_to_many-actions-"`:
   ```elixir
   RoutesHelper.register_crud(
     ActionIconsIndexTest.Product,
     "action-icons-index-products"
   )
   ```
10. Regenerate: `mix auix.gen.stylesheet` (the `assets/css/auix-*.css` output is gitignored), then `mix auix.gen.tailwind_classes`, and commit `priv/static/classes.js` when it changes.

##### Acceptance criteria
- [ ] AC-1: Given `index_columns(:product, [:reference, :name], action_icons: [...])` with no `default_new` entry and three products, visiting `/action-icons-index-products`, then `a[name='auix-new-product']` carries `title="New Product"` and `aria-label="New Product"`, holds `span.auix-action-icon span.hero-plus` and `span.auix-action-label` with the text `New Product`; `button[name='auix-selected_check_all-product']` carries `title="Check all"` and holds `span.auix-action-icon span.hero-check-circle`
- [ ] AC-2: Given `action_icons: [default_row_show: "★", default_row_edit: "/images/edit.svg", default_row_delete: &__MODULE__.delete_icon/1]` where `delete_icon/1` returns `"hero-x-mark"`, then `a[name='auix-show-product']` holds `span.auix-action-icon-text` with the text `★`, `a[name='auix-edit-product']` holds `img.auix-action-icon-image[src='/images/edit.svg']`, `a[name='auix-delete-product']` holds `span.hero-x-mark` and no `span.hero-trash`
- [ ] AC-3: Given `action_icons: [default_selected_delete_all: "hero-archive-box-x-mark"]`, after clicking `button[name='auix-selected_check_all-product']`, then `#auix-delete-all-button-product>button` carries `title="Delete selected"` and holds both `span.hero-archive-box-x-mark` and the count badge `span.auix-button-badge`
- [ ] AC-4: `index_columns :product, [:reference], action_icons: [default_sort: "hero-bolt"]` fails compilation with a `Spark.Error.DslError` matching `index layout: unknown options [:default_sort], valid options are: [:default_row_show, …` (error path)
- [ ] AC-5: `Actions.icon/4` returns the default icon for a missing entry, the entry itself for a value, the function's result for a function entry; `Actions.label_title/1` returns `nil` for `nil` and for a rendered template; `Action.default_icons(:many_to_many)` is `[]` (empty path)
- [ ] AC-6: `Base.rule(:auix_action_icon)` and `Base.rule(:auix_action_label)` each hold `@media (max-width: 640px)`
- [ ] AC-7: at a viewport of 640px and below, every index text button shows only its icon; from 641px up the index header and selection bar look as before (visual — no red test; verified by `iex -S mix run test/start_test_server.exs` and `/action-icons-index-products` in a browser window resized across 640px)

##### Test ports
- Route `"/action-icons-index-products"` registered in `routes.ex` via `register_crud/2` · layout types `:index` · observable: `has_element?/2` on `a[name='auix-new-product']`, `a[name='auix-show-product']`, `a[name='auix-edit-product']`, `a[name='auix-delete-product']`, `button[name='auix-selected_check_all-product']`, `#auix-delete-all-button-product>button`

##### Red tests
| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1 | new file (`rg -n 'action_icons' test` returns nothing) | module `Aurora.UixWeb.Test.ActionIconsIndexTest`: `use Aurora.UixWeb.Test.UICase, :phoenix_case`, `use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test`; `@spec delete_icon(map()) :: binary()` + `def delete_icon(_assigns), do: "hero-x-mark"`; `auix_resource_metadata(:product, context: Inventory, schema: Product)`; `auix_create_ui do index_columns(:product, [:reference, :name], action_icons: [default_row_show: "★", default_row_edit: "/images/edit.svg", default_row_delete: &__MODULE__.delete_icon/1, default_selected_delete_all: "hero-archive-box-x-mark"]) end`; each test: `delete_all_inventory_data()`, `create_sample_products(3, :test)`, `live(conn, "/action-icons-index-products")` | `test/cases_live/action_icons_index_test.exs` | `"default actions show their default icon and keep their label"` | `has_element?(view, "a[name='auix-new-product'][title='New Product'][aria-label='New Product'] span.auix-action-icon span.hero-plus")`; `has_element?(view, "a[name='auix-new-product'] span.auix-action-label", "New Product")`; `has_element?(view, "button[name='auix-selected_check_all-product'][title='Check all'] span.auix-action-icon span.hero-check-circle")` |
| AC-2 | same new file | as AC-1 | `test/cases_live/action_icons_index_test.exs` | `"action_icons replaces the icon of the row actions"` | `has_element?(view, "a[name='auix-show-product'] span.auix-action-icon-text", "★")`; `has_element?(view, "a[name='auix-edit-product'] img.auix-action-icon-image[src='/images/edit.svg']")`; `has_element?(view, "a[name='auix-delete-product'] span.hero-x-mark")`; `refute has_element?(view, "a[name='auix-delete-product'] span.hero-trash")` |
| AC-3 | same new file | as AC-1, then `view \|> element("button[name='auix-selected_check_all-product']") \|> render_click()` | `test/cases_live/action_icons_index_test.exs` | `"Delete selected keeps its badge with an overridden icon"` | `has_element?(view, "#auix-delete-all-button-product>button[title='Delete selected'] span.hero-archive-box-x-mark")`; `has_element?(view, "#auix-delete-all-button-product>button span.auix-button-badge")` |
| AC-4 | add to `test/cases/create_ui_validation_test.exs`, after the test `"an unknown layout option fails compilation"` | the file's `compile/1` helper | `test/cases/create_ui_validation_test.exs` | `"an index action_icons key that is not a button or link action fails compilation"` | `assert_raise DslError, ~r/index layout: unknown options \[:default_sort\], valid options are: \[:default_row_show,/, fn -> compile("  auix_create_ui do\n    index_columns :product, [:reference], action_icons: [default_sort: \"hero-bolt\"]\n  end\n") end` |
| AC-5 | new file (`ls test/cases/templates/basic` lists no actions test) | module `Aurora.Uix.Templates.Basic.ActionsIconTest`, `use ExUnit.Case, async: true`, `import Phoenix.Component, only: [sigil_H: 2]`, aliases `Aurora.Uix.Action` and `Aurora.Uix.Templates.Basic.Actions`; `def name_icon(%{auix: %{name: name}}), do: "hero-#{name}"` | `test/cases/templates/basic/actions_icon_test.exs` | `"icon/4 resolves the default, a value and a function"`; `"label_title/1 gives text labels only"` | `Actions.icon(%{}, [], :index, :default_new) == "hero-plus"`; `Actions.icon(%{}, [default_new: :"hero-bolt"], :index, :default_new) == :"hero-bolt"`; `Actions.icon(%{auix: %{name: "star"}}, [default_new: &__MODULE__.name_icon/1], :index, :default_new) == "hero-star"`; `Action.default_icons(:many_to_many) == []`; `Actions.label_title("New") == "New"`; `Actions.label_title(:new) == "new"`; `Actions.label_title(nil) == nil`; `assigns = %{}` then `Actions.label_title(~H"<b>New</b>") == nil` |
| AC-6 | add to `test/cases/templates/theme_rules_test.exs`, a new `describe "action icon rules"` after the `describe "rules/0"` block | `alias Aurora.Uix.Templates.Basic.Themes.Base` (already aliased) | `test/cases/templates/theme_rules_test.exs` | `"hide the label and show the icon below the sm breakpoint"` | `assert Base.rule(:auix_action_icon) =~ "@media (max-width: 640px)"`; `assert Base.rule(:auix_action_label) =~ "@media (max-width: 640px)"` |

##### Modules & components
1. `Aurora.Uix.Action` at `lib/aurora_uix/action.ex` — modified: `@default_icons`, `@icon_type`, `default_icons/1`, `default_icon/2`, `icons_schema/1` (new)
2. `Aurora.Uix.Templates.Basic.Actions` at `lib/aurora_uix/templates/basic/actions.ex` — modified: `icon/4`, `label_title/1` (new)
3. `Aurora.Uix.Layout.Options.Index` at `lib/aurora_uix/layout/options/index.ex` — modified: option `:action_icons`
4. `Aurora.Uix.Templates.Basic.Actions.Index` at `lib/aurora_uix/templates/basic/actions/index.ex` — modified; not a renderer, no `default_renderer.ex` dispatch
5. Components: `<.icon>`, `<.button>`, `<.auix_link>` reused. New in `CoreComponents`, each with `resolve_component_for/1`:
   - `action_icon/1` — attrs `icon` (`:any`, required), `class` (`:string`, default `nil`); no slots; renders `span.hero-*`, `img.auix-action-icon-image[src]`, `span.auix-action-icon-text`
   - `action_content/1` — attrs `icon` (`:any`, required), `label` (`:any`, required), `icon_always?` (`:boolean`, default `false`), `icon_class` (`:string`, default `"auix-icon-size-button"`); no slots; renders `span.auix-action-icon` (only when `icon_always?` is `false`) and `span.auix-action-label`
   - `ConfirmButton` — new optional assign `:title`, on the main button as `title` and `aria-label`
6. Theme: `auix-action-icon` (`rule(:auix_action_icon, …)`), `auix-action-label` (`rule(:auix_action_label, …)`), `auix-action-icon-image` (`rule(:auix_action_icon_image, …)`), `auix-action-icon-text` (`rule(:auix_action_icon_text, …)`) in `themes/base.ex`; regenerate with `mix auix.gen.stylesheet` and `mix auix.gen.tailwind_classes`
7. `dt/1` strings: no new msgid. The labels keep their msgids: `"Delete selected"`, `"Uncheck all"`, `"Check all"`, `"De-selecting all items. Selection is disabled for a while... Click to cancel"`, `"Selecting all items. Selection is disabled for a while... Click to cancel"`, `"Clear Filters"`, `"Submit"`; `new_action_label` stays a dynamic `dt/1`

##### Green tests
1. The red tests above pass, unmodified (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs
   only this section's test files)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-1:end -->
<!-- section:UI-2:start -->
### UI-2 — UI · form and show default actions
Depends on: UI-1

#### Documentation references
- `guides/customization/custom_actions.md` § Action Icons (written by DOC-1)
- `guides/core/layouts.md` § Form Layout Options, § Show Layout Options

Layout types: `:form` (`default_save`) and `:show` (`default_edit`, `default_back`). `:index` is UI-1's. Backend-agnostic: no file under `lib/aurora_uix/integration/` changes.

#### Implementation details
1. `lib/aurora_uix/layout/options/form.ex` — modified.
   a. Insert `alias Aurora.Uix.Action` on the line before `alias Aurora.Uix.Layout.Options, as: LayoutOptions`.
   b. Insert `@action_icons {:keyword_list, Action.icons_schema(:form)}` on the line after `@record_navigator {:or, [:atom, {:list, :atom}, {:fun, 1}]}`.
   c. Insert `option(:action_icons, @action_icons)` on the line after `option(:unsaved_changes_guard_disabled?, {:or, [:boolean, {:fun, 1}]})`.
   d. Insert `defp get_default(_assigns, :action_icons), do: {:ok, []}` on the line before `defp get_default(_assigns, option), do: {:not_found, option}`.
   e. `@moduledoc` › `## Options` — insert after the `:unsaved_changes_guard_disabled?` bullet and its sub-bullets:
      ```
      * `:action_icons` - The icon of the save action: `[default_save: icon]`. Below the `sm`
        breakpoint the save button shows only its icon.
        - Accepts a keyword list; an unknown key fails compilation. The icon takes the values of
          `Aurora.Uix.Layout.Options.Index`'s `:action_icons`.
        - Default: `[]` (the save action keeps `hero-check`).
      ```
2. `lib/aurora_uix/layout/options/show.ex` — modified.
   a. Insert `alias Aurora.Uix.Action` on the line before `alias Aurora.Uix.Layout.Options, as: LayoutOptions`.
   b. Insert `@action_icons {:keyword_list, Action.icons_schema(:show)}` on the line after `@record_navigator {:or, [:atom, {:list, :atom}, {:fun, 1}]}`.
   c. Insert `option(:action_icons, @action_icons)` on the line after `option(:record_navigator, @record_navigator)`.
   d. Insert `defp get_default(_assigns, :action_icons), do: {:ok, []}` on the line before `defp get_default(_assigns, option), do: {:not_found, option}`.
   e. `@moduledoc` › `## Options` — insert after the `:record_navigator` bullet and its sub-bullets:
      ```
      * `:action_icons` - The icons of the edit and back actions: `[default_edit: icon, default_back: icon]`.
        Below the `sm` breakpoint the edit button and the back link show only their icons.
        - Accepts a keyword list; an unknown key fails compilation. An icon takes the values of
          `Aurora.Uix.Layout.Options.Index`'s `:action_icons`.
        - Default: `[]` (edit keeps `hero-pencil`, back keeps `hero-arrow-left`).
      ```
3. `lib/aurora_uix/templates/basic/actions/form.ex` — modified. Replace the body of `save_action/1` with:
   ```elixir
   label = dt(assigns.auix.layout_options.save_action_label)

   assigns =
     assigns
     |> Map.put(
       :icon,
       Actions.icon(assigns, assigns.auix.layout_options.action_icons, :form, :default_save)
     )
     |> Map.put(:label, label)
     |> Map.put(:title, Actions.label_title(label))

   ~H"""
   <.button phx-disable-with={dt("Saving...")} name={"auix-save-#{@auix.module}"} title={@title} aria-label={@title}><.action_content icon={@icon} label={@label} /></.button>
   """
   ```
4. `lib/aurora_uix/templates/basic/components/routing_components.ex` — modified. `auix_back/1`: insert `attr(:icon, :any, default: "hero-arrow-left", doc: "the icon before the content, as `action_icon/1` takes it")` on the line after its `attr(:host_components, :any)`; replace its `<.icon name="hero-arrow-left" class="auix-icon-size-3" />` with `<.action_icon icon={@icon} class="auix-icon-size-3" />`. Its `## Attributes` doc gains the line `- icon - The icon before the content (default `"hero-arrow-left"`)`. `<.back>` in `core_components.ex` stays unchanged.
5. `lib/aurora_uix/templates/basic/actions/show_component.ex` — modified.
   a. `## PRIVATE` — insert on the line after `## PRIVATE`:
      ```elixir
      # Puts the icon, the label and the title of a show default action in the assigns.
      @spec put_action(map(), atom(), term()) :: map()
      defp put_action(assigns, action_name, label) do
        assigns
        |> Map.put(
          :icon,
          Actions.icon(assigns, assigns.auix.layout_options.action_icons, :show, action_name)
        )
        |> Map.put(:label, label)
        |> Map.put(:title, Actions.label_title(label))
      end
      ```
   b. `edit_header_action/1` — in both clauses insert before `~H"""`:
      ```elixir
      assigns = put_action(assigns, :default_edit, dt(assigns.auix.layout_options.edit_action_label))
      ```
      replace `<.button>{dt(@auix.layout_options.edit_action_label)}</.button>` with `<.button><.action_content icon={@icon} label={@label} /></.button>`, and on the `<.auix_link …>` opening tag add `title={@title} aria-label={@title}` after `name={"auix-edit-#{@auix.module}"}`.
   c. `back_footer_action/1` — in both clauses insert before `~H"""`:
      ```elixir
      assigns = put_action(assigns, :default_back, dt(assigns.auix.layout_options.back_action_label))
      ```
      Replace `<.auix_back phx-target={@auix._myself}>{dt(@auix.layout_options.back_action_label)}</.auix_back>` with `<.auix_back phx-target={@auix._myself} icon={@icon} title={@title} aria-label={@title}><span class="auix-action-label">{@label}</span></.auix_back>`. Replace `<.auix_back>{dt(@auix.layout_options.back_action_label)}</.auix_back>` with `<.auix_back icon={@icon} title={@title} aria-label={@title}><span class="auix-action-label">{@label}</span></.auix_back>`. The arrow shows at every width, as it does today; below the `sm` breakpoint only the label hides.
   d. `@moduledoc` › `## Key Features` — append the bullet:
      `- The edit and back actions take their icons from the layout's `action_icons:` option; below the `sm` breakpoint they show only their icons.`
6. Markup changes (Writing rule 6). `a[name='auix-edit-product']`, `button[name='auix-save-product']` and `div[name='auix-show-navigate-back'] a` keep their selectors, and their trimmed texts stay `Edit Product`, `Save Product` and `Back to Products`. The tests that drive them keep their drive unchanged: `test/cases_live/create_ui_actions_form_test.exs` (`LazyHTML.text` of `[name='auix-save-product']` equals `"Save Product"` after `String.trim`), `test/cases_live/create_ui_actions_show_test.exs` (`"Back to Products"`), `test/cases_live/create_ui_layout_test.exs` (`div[name='auix-show-navigate-back'] a:nth-of-type(1)`), `test/cases_live/components_form_show_test.exs` (clicks `div[name='auix-show-navigate-back'] a`), `test/cases/routing_components_test.exs` (`<.auix_back phx-target="#c">`).
7. `test/support/app_web/routes.ex` — insert after the four-line `RoutesHelper.register_product_crud(` call whose arguments are `CreateUIActionsFormTest,` and `"create-ui-actions-form-"`:
   ```elixir
   RoutesHelper.register_crud(
     ActionIconsFormShowTest.Product,
     "action-icons-form-show-products"
   )
   ```

##### Acceptance criteria
- [ ] AC-1: Given `edit_layout :product, action_icons: [default_save: "hero-bolt"]`, visiting `/action-icons-form-show-products/<id>/edit`, then `button[name='auix-save-product']` carries `title="Save Product"` and `aria-label="Save Product"`, holds `span.auix-action-icon span.hero-bolt` and `span.auix-action-label` with the text `Save Product`
- [ ] AC-2: Given `show_layout :product, action_icons: [default_back: "←"]`, visiting `/action-icons-form-show-products/<id>/show`, then `a[name='auix-edit-product']` carries `title="Edit Product"` and holds `span.auix-action-icon span.hero-pencil`; `div[name='auix-show-navigate-back'] a` carries `title="Back to Products"`, holds `span.auix-action-icon-text` with the text `←` and `span.auix-action-label` with the text `Back to Products`
- [ ] AC-3: `edit_layout :product, action_icons: [default_back: "←"]` fails compilation with a `Spark.Error.DslError` matching `form layout: unknown options [:default_back], valid options are: [:default_save]` (error path)
- [ ] AC-4: at a viewport of 640px and below, the save and edit buttons show only their icons and the back link only its arrow; from 641px up they look as before (visual — no red test; verified by `iex -S mix run test/start_test_server.exs` and `/action-icons-form-show-products` in a browser window resized across 640px)

##### Test ports
- Route `"/action-icons-form-show-products"` registered in `routes.ex` via `register_crud/2` · layout types `:form`, `:show` · observable: `has_element?/2` on `button[name='auix-save-product']`, `a[name='auix-edit-product']`, `div[name='auix-show-navigate-back'] a`

##### Red tests
| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1 | new file (`rg -n 'action_icons' test` lists only UI-1's files) | module `Aurora.UixWeb.Test.ActionIconsFormShowTest`: `use Aurora.UixWeb.Test.UICase, :phoenix_case`, `use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test`; `auix_resource_metadata(:product, context: Inventory, schema: Product)`; `auix_create_ui do edit_layout :product, action_icons: [default_save: "hero-bolt"] do inline([:reference, :name]) end; show_layout :product, action_icons: [default_back: "←"] do inline([:reference, :name]) end end`; each test: `delete_all_inventory_data()`, `product_id = 1 \|> create_sample_products(:test) \|> get_in(["id_test-1", Access.key!(:id)])` | `test/cases_live/action_icons_form_show_test.exs` | `"the save action shows its icon and keeps its label"` | `{:ok, view, _html} = live(conn, "/action-icons-form-show-products/#{product_id}/edit")`; `has_element?(view, "button[name='auix-save-product'][title='Save Product'][aria-label='Save Product'] span.auix-action-icon span.hero-bolt")`; `has_element?(view, "button[name='auix-save-product'] span.auix-action-label", "Save Product")` |
| AC-2 | same new file | as AC-1 | `test/cases_live/action_icons_form_show_test.exs` | `"the edit and back actions show their icons and keep their labels"` | `{:ok, view, _html} = live(conn, "/action-icons-form-show-products/#{product_id}/show")`; `has_element?(view, "a[name='auix-edit-product'][title='Edit Product'] span.auix-action-icon span.hero-pencil")`; `has_element?(view, "div[name='auix-show-navigate-back'] a[title='Back to Products'] span.auix-action-icon-text", "←")`; `has_element?(view, "div[name='auix-show-navigate-back'] a span.auix-action-label", "Back to Products")` |
| AC-3 | add to `test/cases/create_ui_validation_test.exs`, after the test `"a layout option of the wrong type fails compilation"` | the file's `compile/1` helper | `test/cases/create_ui_validation_test.exs` | `"a form action_icons key of another layout fails compilation"` | `assert_raise DslError, ~r/form layout: unknown options \[:default_back\], valid options are: \[:default_save\]/, fn -> compile("  auix_create_ui do\n    edit_layout :product, action_icons: [default_back: \"←\"] do\n      inline [:reference]\n    end\n  end\n") end` |

##### Modules & components
1. `Aurora.Uix.Layout.Options.Form` at `lib/aurora_uix/layout/options/form.ex` — modified: option `:action_icons`
2. `Aurora.Uix.Layout.Options.Show` at `lib/aurora_uix/layout/options/show.ex` — modified: option `:action_icons`
3. `Aurora.Uix.Templates.Basic.Actions.Form` at `lib/aurora_uix/templates/basic/actions/form.ex` — modified
4. `Aurora.Uix.Templates.Basic.Actions.ShowComponent` at `lib/aurora_uix/templates/basic/actions/show_component.ex` — modified
5. Components: `<.button>`, `<.auix_link>`, `<.action_content>` and `<.action_icon>` (UI-1) reused. `auix_back/1` in `routing_components.ex` gains attr `icon` (`:any`, default `"hero-arrow-left"`); slot `inner_block` unchanged
6. Theme: none (reuses UI-1's `auix-action-*` rules)
7. `dt/1` strings: no new msgid; `save_action_label`, `edit_action_label` and `back_action_label` stay dynamic `dt/1`, `"Saving..."` unchanged

##### Green tests
1. The red tests above pass, unmodified (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs
   only this section's test files)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-2:end -->
<!-- section:UI-3:start -->
### UI-3 — UI · one-to-many and embeds-many default actions
Depends on: UI-1

#### Documentation references
- `guides/customization/custom_actions.md` § Action Icons, § Association Actions
- `guides/core/layouts.md` § Field-Level Options

Layout types: `:form` and `:show`, the layouts one-to-many and embeds-many fields render in; every changed component keeps its `layout_type: :form` guard. Backend-agnostic: the check reads the normalized `%Field{}` atoms `:one_to_many_association` and `:embeds_many`, and no file under `lib/aurora_uix/integration/` changes. No `%Field{}` type atom is added.

#### Implementation details
1. `lib/aurora_uix/layout/node/field.ex` — modified (contract change: new struct key).
   a. `defstruct` — insert `action_icons: [],` on the line after `actions: [],`.
   b. `@type t()` — insert `action_icons: keyword(),` on the line after `actions: keyword(),`.
   c. `@moduledoc` › `## Key Constraints` — replace `` - `actions`, `order_by` and `where` apply to association fields. `` with `` - `actions`, `action_icons`, `order_by` and `where` apply to association fields. ``
   Every `%Node.Field{}` built elsewhere (`RenderTree.default/3`, `CreateUI.Dsl.field_node/1`, the tests' struct literals) takes the default `[]` and needs no change.
2. `lib/aurora_uix/layout/create_ui/dsl.ex` — modified.
   a. `@layout_field_schema` — insert after the `where:` entry whose `doc:` is `"For one-to-many fields: filter of the related entries."`, inside the same keyword list:
      ```elixir
      action_icons: [
        type: :keyword_list,
        doc: "For one-to-many and embeds-many fields: the icons of the field's default actions."
      ]
      ```
   b. `field_node_from_opts/2` — insert `action_icons: Keyword.get(opts, :action_icons, []),` on the line after `actions: Keyword.take(opts, @field_action_names),`.
3. `lib/aurora_uix/layout/create_ui.ex` — modified.
   a. Insert `alias Aurora.Uix.Action` on the line before `alias Aurora.Uix.BehaviourHelper`.
   b. `validate_layouts/3` — replace the two-line branch `resource ->` / `validate_fields(layout, resource, module)` of its `case` with:
      ```elixir
      resource ->
        :ok = validate_fields(layout, resource, module)
        validate_action_icons(layout, resource, module)
      ```
   c. Insert after `validate_fields/3` (new; `rg -n 'validate_action_icons|field_action_group' lib` returns nothing):
      ```elixir
      # A field's `action_icons:` keys are the default actions of its own type, which the layout DSL
      # does not know when it reads the field.
      @spec validate_action_icons(Node.layout(), Resource.t(), module()) :: :ok
      defp validate_action_icons(layout, resource, module) do
        layout
        |> Node.fields()
        |> Enum.reject(&(&1.action_icons == []))
        |> Enum.each(&validate_field_action_icons(&1, resource, layout, module))
      end

      @spec validate_field_action_icons(Node.Field.t(), Resource.t(), Node.layout(), module()) :: :ok
      defp validate_field_action_icons(field_node, resource, layout, module) do
        group = resource.fields |> Map.fetch!(field_node.key) |> Map.fetch!(:type) |> field_action_group()
        schema = [action_icons: [type: {:keyword_list, Action.icons_schema(group)}]]

        case Spark.Options.validate([action_icons: field_node.action_icons], schema) do
          {:ok, _validated} ->
            :ok

          {:error, error} ->
            raise DslError,
              module: module,
              path: [:auix_create_ui, layout_type(layout), layout.resource],
              message: "field #{inspect(field_node.key)}: #{Exception.message(error)}"
        end
      end

      @spec field_action_group(atom()) :: atom()
      defp field_action_group(:one_to_many_association), do: :one_to_many
      defp field_action_group(:embeds_many), do: :embeds_many
      defp field_action_group(_type), do: :none
      ```
      `Action.icons_schema(:none)` is `[]`, so every key on a many-to-many, multi-select, scalar field fails with `valid options are: []`. `validate_fields/3` runs first, so `Map.fetch!/2` finds every key.
4. `lib/aurora_uix/templates/basic/actions/one_to_many.ex` — modified.
   a. `## PRIVATE` — insert on the line after `## PRIVATE`:
      ```elixir
      # The icon of a one-to-many default action: the field's `action_icons:` entry, else its default.
      @spec resolve_icon(map(), atom()) :: atom() | binary()
      defp resolve_icon(assigns, action_name) do
        icons = Map.get(assigns.auix.layout_tree, :action_icons, [])
        Actions.icon(assigns, icons, :one_to_many, action_name)
      end
      ```
      `assigns.auix.layout_tree` is the field's `%Node.Field{}`: `Renderer.render_inner_elements/1` puts it there, and `Renderers.OneToMany.render/1` passes the same `auix` to the header actions and, through `one_to_many`, to `child_rows/1` for the row actions.
   b. In each listed clause, insert the first line before `~H"""` and replace the icon line:

      | Function | Clause | First line | Replace | With |
      |---|---|---|---|---|
      | `add_new_child/1` | `%{auix: %{layout_type: :form}}` | `assigns = Map.put(assigns, :icon, resolve_icon(assigns, :default_new))` | `<.icon name="hero-plus" class="auix-icon-size-button"/>` | `<.action_icon icon={@icon} class="auix-icon-size-button" />` |
      | `show_child_action/1` | the clause without `notify` | `assigns = Map.put(assigns, :icon, resolve_icon(assigns, :default_row_show))` | `<.icon name="hero-eye" class="auix-icon-info"/>` | `<.action_icon icon={@icon} class="auix-icon-info" />` |
      | `edit_child_action/1` | `%{auix: %{layout_type: :form}}` | `assigns = Map.put(assigns, :icon, resolve_icon(assigns, :default_row_edit))` | `<.icon name="hero-pencil" class="auix-icon-safe"/>` | `<.action_icon icon={@icon} class="auix-icon-safe" />` |
      | `delete_child_action/1` | `%{auix: %{layout_type: :form}}` | `assigns = Map.put(assigns, :icon, resolve_icon(assigns, :default_row_delete))` | `<.icon name="hero-trash" class="auix-icon-danger"/>` | `<.action_icon icon={@icon} class="auix-icon-danger" />` |
   c. `@moduledoc` › `## Key Features` — append the bullet:
      `- The new, show, edit and delete actions take their icons from the field's `action_icons:` option.`
5. `lib/aurora_uix/templates/basic/components/embeds_many_component.ex` — modified. `update/2`: insert `|> assign_auix(:embeds_many_action_icons, Map.get(assigns.auix.layout_tree, :action_icons, []))` on the line before `|> assign_auix(:layout_tree, layout_tree)`. The incoming `assigns.auix.layout_tree` is the embeds-many field's `%Node.Field{}` (`EmbedsManyRenderer.render/1` passes the field's `auix`); the next line replaces it with the embedded resource's layout, so the icons are kept first.
6. `lib/aurora_uix/templates/basic/actions/embeds_many.ex` — modified.
   a. `## PRIVATE` — insert on the line after `## PRIVATE`:
      ```elixir
      # The icon of an embeds-many default action: the field's `action_icons:` entry, else its default.
      @spec resolve_icon(map(), atom()) :: atom() | binary()
      defp resolve_icon(assigns, action_name),
        do: Actions.icon(assigns, assigns.auix.embeds_many_action_icons, :embeds_many, action_name)
      ```
   b. `header_enable_add_entry/1`, the `layout_type: :form` clause — replace the body with:
      ```elixir
      assigns =
        assigns
        |> Map.put(:icon, resolve_icon(assigns, :default_header_enable_add_entry))
        |> Map.put(:label, dt("Add new entry"))

      ~H"""
        <.button class="auix-button--alt" type="button" phx-click="toggle-add-embeds" phx-target={@target} title={@label} aria-label={@label}>
          <.action_content icon={@icon} label={@label} icon_always?={true} />
        </.button>
      """
      ```
   c. `footer_enable_add_entry/1`, the `layout_type: :form` clause — replace the body with:
      ```elixir
      assigns =
        assigns
        |> Map.put(:icon, resolve_icon(assigns, :default_footer_enable_add_entry))
        |> Map.put(:label, dt("Add new entry"))

      ~H"""
        <%= if Enum.count(@auix.form[@field.key].value) > 0 do %>
          <.button type="button" class="auix-button--alt" phx-click="toggle-add-embeds" phx-target={@target} title={@label} aria-label={@label}>
            <.action_content icon={@icon} label={@label} icon_always?={true} />
          </.button>
        <% end %>
      """
      ```
   d. `add_entry/1`, the `layout_type: :form, new_entry_form: new_entry_form` clause — replace the body with:
      ```elixir
      disabled = Map.get(new_entry_form, :errors) != [] or Map.get(new_entry_form, :action) == nil

      assigns =
        assigns
        |> Map.put(:disabled, disabled)
        |> Map.put(:icon, resolve_icon(assigns, :default_add_entry))
        |> Map.put(:label, dt("Add"))

      ~H"""
        <.button type="submit" class="auix-button--alt" form={@form_id} phx-target={@target}
            disabled={@disabled} title={@label} aria-label={@label}>
          <.action_content icon={@icon} label={@label} icon_always?={true} />
        </.button>
      """
      ```
   e. `remove_entry/1`, the `layout_type: :form` clause — insert before `~H"""`:
      ```elixir
      assigns = Map.put(assigns, :icon, resolve_icon(assigns, :default_remove_entry))
      ```
      and replace `<.icon class="auix-icon-size-5 auix-icon-danger" name="hero-trash" />` with `<.action_icon icon={@icon} class="auix-icon-size-5 auix-icon-danger" />`.
   f. `@moduledoc` › `## Key Features` — append the bullet:
      `- The add-entry and remove-entry actions take their icons from the field's `action_icons:` option; below the `sm` breakpoint the add-entry buttons show only their icons.`
7. Markup changes (Writing rule 6). `button[phx-click='toggle-add-embeds']`, `div[name='auix-embeds_many-header_actions'] > button[phx-click='toggle-add-embeds']` and the one-to-many link names keep their values; the header and row links stay text-free with a default icon. The tests that drive them keep their drive unchanged: `test/cases_live/ash_actor_policy_test.exs` (`[phx-click='toggle-add-embeds']`), `test/browser_cases/embeds_many_test.exs` and `test/browser_cases/ash_embeds_test.exs` (`div[name='auix-embeds_many-header_actions'] > button[phx-click='toggle-add-embeds']`), `test/cases_live/association_one2many_ui_actions_test.exs` (link texts `["", "custom new"]` and `["", "Custom edit", ""]`).
8. `test/support/app_web/routes.ex` — insert after the four-line `RoutesHelper.register_user_crud(` call whose arguments are `EmbedsManyTest,` and `"embeds-many-"`:
   ```elixir
   RoutesHelper.register_crud(
     ActionIconsFieldsTest.Product,
     "action-icons-fields-products"
   )

   RoutesHelper.register_crud(
     ActionIconsFieldsTest.ProductTransaction,
     "action-icons-fields-product_transactions"
   )

   RoutesHelper.register_crud(
     ActionIconsFieldsTest.User,
     "action-icons-fields-users"
   )
   ```

##### Acceptance criteria
- [ ] AC-1: Given `edit_layout :product` with `product_transactions: [action_icons: [default_new: "hero-sparkles", default_row_edit: "hero-pencil-square"]]` and a product with three transactions, visiting `/action-icons-fields-products/<id>/edit`, then `div[name='auix-one_to_many-product'] [name='auix-one_to_many-header-actions'] a` holds `span.hero-sparkles`, the first transaction row's `a[name^='auix-edit-']` holds `span.hero-pencil-square`, and its `a[name^='auix-show-']` keeps `span.hero-eye`
- [ ] AC-2: Given `edit_layout :user` with `emails: [action_icons: [default_header_enable_add_entry: "hero-sparkles", default_remove_entry: "hero-x-mark"]]` and a user with one email, visiting `/action-icons-fields-users/<id>/edit`, then `div[name='auix-embeds_many-header_actions'] > button[title='Add new entry']` holds `span.hero-sparkles` and `span.auix-action-label` with the text `Add new entry`, `div[name='auix-embeds_many-footer_actions'] button` keeps `span.hero-plus`, and `#auix-remove-button-0 button` holds `span.hero-x-mark`
- [ ] AC-3: `product_transactions: [action_icons: [default_add_entry: "hero-plus"]]` fails compilation with a `Spark.Error.DslError` matching `field :product_transactions: unknown options [:default_add_entry], valid options are: [:default_new, :default_row_show, :default_row_edit, :default_row_delete]` (error path)
- [ ] AC-4: `suppliers: [action_icons: [default_toggle_all: "hero-check"]]` on the many-to-many field fails compilation with a `Spark.Error.DslError` matching `field :suppliers: unknown options [:default_toggle_all], valid options are: []` (error path)
- [ ] AC-5: at a viewport of 640px and below, the embeds-many add-entry buttons show only their `+` icon; from 641px up they look as before (visual — no red test; verified by `iex -S mix run test/start_test_server.exs` and `/action-icons-fields-users/<id>/edit` in a browser window resized across 640px)

##### Test ports
- Routes `"/action-icons-fields-products"`, `"/action-icons-fields-product_transactions"` and `"/action-icons-fields-users"` registered in `routes.ex` via `register_crud/2` · layout types `:form` · observable: `has_element?/2` on `div[name='auix-one_to_many-product'] …`, `div[name='auix-embeds_many-header_actions'] > button`, `div[name='auix-embeds_many-footer_actions'] button`, `#auix-remove-button-0 button`

##### Red tests
| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1 | new file (`rg -n 'action_icons' test` lists only UI-1's and UI-2's files) | module `Aurora.UixWeb.Test.ActionIconsFieldsTest`: `use Aurora.UixWeb.Test.UICase, :phoenix_case`, `use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test`; `auix_resource_metadata` for `:product_location` (`ProductLocation`), `:product_transaction` (`ProductTransaction`), `:product` (`Product`) with `context: Inventory`, and `:user` (`User`) with `context: Accounts`; `auix_create_ui do edit_layout :product do stacked([:reference, :name, product_transactions: [action_icons: [default_new: "hero-sparkles", default_row_edit: "hero-pencil-square"]]]) end; edit_layout :user do stacked([:given_name, emails: [action_icons: [default_header_enable_add_entry: "hero-sparkles", default_remove_entry: "hero-x-mark"]]]) end end`; `delete_all_inventory_data()`, `product_id = 1 \|> create_sample_products_with_transactions(3, :test) \|> List.first() \|> elem(1) \|> Map.get(:id)` | `test/cases_live/action_icons_fields_test.exs` | `"one-to-many actions take the field's action_icons"` | `{:ok, view, _html} = live(conn, "/action-icons-fields-products/#{product_id}/edit")`; `has_element?(view, "div[name='auix-one_to_many-product'] [name='auix-one_to_many-header-actions'] a span.hero-sparkles")`; `has_element?(view, "div[name='auix-one_to_many-product'] tbody tr:nth-of-type(1) a[name^='auix-edit-'] span.hero-pencil-square")`; `has_element?(view, "div[name='auix-one_to_many-product'] tbody tr:nth-of-type(1) a[name^='auix-show-'] span.hero-eye")` |
| AC-2 | same new file | as AC-1, then `delete_all_accounts_data()`, `user = 1 \|> create_sample_users(%{emails: [%{email: "work@test.com", name: "Work"}]}) \|> List.first()` | `test/cases_live/action_icons_fields_test.exs` | `"embeds-many actions take the field's action_icons"` | `{:ok, view, _html} = live(conn, "/action-icons-fields-users/#{user.id}/edit")`; `has_element?(view, "div[name='auix-embeds_many-header_actions'] > button[title='Add new entry'] span.hero-sparkles")`; `has_element?(view, "div[name='auix-embeds_many-header_actions'] > button span.auix-action-label", "Add new entry")`; `has_element?(view, "div[name='auix-embeds_many-footer_actions'] button span.hero-plus")`; `has_element?(view, "#auix-remove-button-0 button span.hero-x-mark")` |
| AC-3 | add to `test/cases/create_ui_validation_test.exs`, after the test `"an unknown field option fails compilation"` | the file's `compile/1` helper | `test/cases/create_ui_validation_test.exs` | `"a one-to-many field rejects an action_icons key of another field type"` | `assert_raise DslError, ~r/field :product_transactions: unknown options \[:default_add_entry\], valid options are: \[:default_new, :default_row_show, :default_row_edit, :default_row_delete\]/, fn -> compile("  auix_create_ui do\n    edit_layout :product do\n      inline [:reference, product_transactions: [action_icons: [default_add_entry: \"hero-plus\"]]]\n    end\n  end\n") end` |
| AC-4 | add to `test/cases/create_ui_validation_test.exs`, after the AC-3 test | the file's `compile/1` helper | `test/cases/create_ui_validation_test.exs` | `"a many-to-many field takes no action_icons key"` | `assert_raise DslError, ~r/field :suppliers: unknown options \[:default_toggle_all\], valid options are: \[\]/, fn -> compile("  auix_create_ui do\n    edit_layout :product do\n      inline [:reference, suppliers: [action_icons: [default_toggle_all: \"hero-check\"]]]\n    end\n  end\n") end` |

##### Modules & components
1. `Aurora.Uix.Layout.Node.Field` at `lib/aurora_uix/layout/node/field.ex` — modified: key `action_icons` (default `[]`)
2. `Aurora.Uix.Layout.CreateUI.Dsl` at `lib/aurora_uix/layout/create_ui/dsl.ex` — modified: field option `action_icons`
3. `Aurora.Uix.Layout.CreateUI` at `lib/aurora_uix/layout/create_ui.ex` — modified: `validate_action_icons/3`, `validate_field_action_icons/4`, `field_action_group/1` (new, private)
4. `Aurora.Uix.Templates.Basic.Actions.OneToMany` at `lib/aurora_uix/templates/basic/actions/one_to_many.ex` — modified; the field renderer `Renderers.OneToMany` stays dispatched from `default_renderer.ex` clause `def render(%{field: %{type: :one_to_many_association}} = assigns),` unchanged
5. `Aurora.Uix.Templates.Basic.EmbedsManyComponent` at `lib/aurora_uix/templates/basic/components/embeds_many_component.ex` — modified: `auix` key `:embeds_many_action_icons`
6. `Aurora.Uix.Templates.Basic.Actions.EmbedsMany` at `lib/aurora_uix/templates/basic/actions/embeds_many.ex` — modified; `EmbedsManyRenderer` stays dispatched from `default_renderer.ex` clause `def render(%{field: %{type: :embeds_many}} = assigns),` unchanged
7. Components: `<.button>`, `<.auix_link>`, `<.link>`, `ConfirmButton`, `<.action_icon>` and `<.action_content>` (UI-1) reused; no new component
8. Theme: none (reuses UI-1's `auix-action-*` rules)
9. `dt/1` strings: no new msgid; `"Add new entry"` and `"Add"` keep their msgids

##### Green tests
1. The red tests above pass, unmodified (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs
   only this section's test files)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-3:end -->

---

### Out of Scope
- `:default_toggle_all_selected`, `:default_sort`, `:default_pagination` and the many-to-many and multi-select `:default_toggle_all` take no `action_icons:` key: they render a checkbox, a select and a pager, not a button with a label. Writing one of them fails compilation with the unknown-key error that lists the valid keys; many-to-many and multi-select fields therefore have no `action_icons:` keys.
- Custom actions: the library cannot know their names, so it resolves no icon for them and their markup stays the same at every width. The host makes one follow the breakpoint with `<.action_content>`; DOC-1 shows how.
- No parser, CRUD, query change: the feature reads layout options and the normalized `%Field{}` type atoms only, so it behaves the same over Ash and Ecto (`ctx`), and no backend section exists.
- Icon-only actions (row actions, one-to-many header, filter toggle, embeds-many remove) gain no `title` and no `aria-label`: they have no label to keep.
- The `<.back>` core component keeps its fixed arrow: no default action renders it.
- The embeds-many field's action operations (`add_header_action:` …) keep reading the embedded resource's form layout, as today; only `action_icons:` is read from the embeds-many field.
<!-- enriched-spec:end -->
