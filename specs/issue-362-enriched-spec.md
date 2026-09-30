<!-- enriched-spec:start v2 -->
## Enriched Spec

**Complexity:** normal

### Overview
Closing the new/edit form modal while the form holds unsaved changes opens a themed confirmation dialog instead of discarding the changes. The form component tracks dirty state server-side and decides every close request; a new `edit_layout` option turns the guard off per resource. The guard lives in the backend-agnostic form handler, so Ash and Ecto resources are both covered, and both are tested.

### Section Map
| ID | Type | Scope | Depends on | Branch | PR title |
|---|---|---|---|---|---|
| DOC-1 | Documentation | CHANGELOG.md § [0.1.6] › Added · guides/core/layouts.md § Form Layout Options · guides/core/liveview.md § Built-in Events · guides/customization/styling.md § Class reference | none | federico/362-doc-1-unsaved-changes-guard | docs: document the unsaved-changes guard on the form modal (#362 · DOC-1) |
| UI-1 | UI | handler + renderers + theme + form layout option · unsaved-changes guard on the form modal | DOC-1 | federico/362-ui-1-unsaved-changes-guard | feat: guard the form modal against discarding unsaved changes (#362 · UI-1) |

A section starts only when every dependency is **merged**. Independent
sections may run in parallel. Status is derived from GitHub, never recorded
here.

<!-- section:DOC-1:start -->
### DOC-1 — Documentation
Depends on: none

#### Documentation references
- `CHANGELOG.md` § `## [0.1.6]` › `### Added`
- `guides/core/layouts.md` § Form Layout Options
- `guides/core/liveview.md` § Built-in Events
- `guides/customization/styling.md` § Class reference
- `guides/customization/styling.md` § The five files and their cascade layers — its existing "Re-run the generator after every upgrade" warning already covers the three new `auix-*` rules; it is not edited.

#### Implementation details

##### CHANGELOG.md
1. § `## [0.1.6]` › `### Added` — insert verbatim as the first entry under the heading, above the `contains` filter entry, followed by one blank line:
   ```
   - **Unsaved-changes guard on the form modal**
     - Closing the new/edit form modal (the × button, `Esc`, a click outside it) threw away whatever
       the user had typed. The form component now records whether a `"validate"` event has changed
       the form since it was opened; when it has, every close path opens a confirmation dialog
       ("Keep editing" / "Discard changes") instead of closing. A form without changes closes exactly
       as before. The show modal is unchanged.
     - The form modal's close paths now push `"auix_request_close"` to the form component, which
       decides server-side; the dialog's buttons push `"auix_keep_editing"` and
       `"auix_discard_changes"`. The guard lives in the backend-agnostic form handler, so Ash and Ecto
       resources behave the same.
     - Opt out per resource with the new `edit_layout` option
       `unsaved_changes_guard_disabled?: true`.
     - `modal/1` gains a `hide_on_cancel?` attribute (default `true`). The form modal sets it to
       `false` so it stays visible while the server decides. A host override of `modal/1` must honour
       it, otherwise the modal hides before the dialog appears.
     - New theme classes `auix-discard-confirm`, `auix-discard-confirm-message` and
       `auix-discard-confirm-actions`: re-run `mix auix.gen.stylesheet` after upgrading.
   ```

##### guides/core/layouts.md
1. § Form Layout Options — in the `**Options:**` list, insert this bullet directly after the `:save_action_label` bullet:
   ```
   - `:unsaved_changes_guard_disabled?` — When `true`, closing the form modal with unsaved changes closes it without asking for confirmation (default: `false`, the guard is on)
   ```

##### guides/core/liveview.md
1. § Built-in Events — in the `**FormComponent (LiveComponent):**` list, insert these three bullets directly after the `"auix_download_upload"` bullet of that list:
   ```
   - `"auix_request_close"` - Close request from the form modal (× button, `Esc`, click outside); closes the modal, or opens the discard-changes dialog when the form has unsaved changes
   - `"auix_keep_editing"` - Close the discard-changes dialog and keep the form open
   - `"auix_discard_changes"` - Drop the unsaved changes and close the form modal
   ```

##### guides/customization/styling.md
1. § Class reference — in the table, insert these three rows directly after the `.auix-modal-close-button` row:
   ```
   | `.auix-discard-confirm` | Discard-changes dialog body inside the form modal | `--auix-gap-default` |
   | `.auix-discard-confirm-message` | Discard-changes dialog message | `--auix-font-size-caption` |
   | `.auix-discard-confirm-actions` | Discard-changes dialog button row | `--auix-gap-default` |
   ```

##### Acceptance criteria
- [ ] AC-1: the CHANGELOG entry sits under the current unreleased version and carries no
      issue-link suffix (mechanical — no red test; verified by
      `git diff origin/main...HEAD -- CHANGELOG.md | grep -E '^\+.*\[#[0-9]+\]'` returning nothing)
- [ ] AC-2: no file outside the documentation set modified, apart from this issue's spec file
      (its AC ticks) (mechanical — no red test; verified by
      `git diff --name-only origin/main...HEAD` listing only `CHANGELOG.md`, `README.md`,
      `CONTRIBUTING.md`, `ROADMAP.md`, `guides/**/*.md` and `specs/issue-362-enriched-spec.md`)
- [ ] AC-3: `guides/core/layouts.md § Form Layout Options` lists `:unsaved_changes_guard_disabled?` directly after `:save_action_label` (mechanical — no red test; verified by `grep -n -A1 'save_action_label' guides/core/layouts.md | grep unsaved_changes_guard_disabled`)
- [ ] AC-4: `guides/core/liveview.md § Built-in Events` lists the three new FormComponent events (mechanical — no red test; verified by `grep -c -E '"auix_(request_close|keep_editing|discard_changes)"' guides/core/liveview.md` printing `3`)
- [ ] AC-5: `guides/customization/styling.md § Class reference` carries the three `.auix-discard-confirm*` rows (mechanical — no red test; verified by `grep -c 'auix-discard-confirm' guides/customization/styling.md` printing `3`)

##### Green checks
1. `mix consistency` clean (code-issue); `mix test` — full suite green
   (review-issue runs the suite)
<!-- section:DOC-1:end -->
<!-- section:UI-1:start -->
### UI-1 — UI · form handler, index + form renderers, modal component, theme, form layout option
Depends on: DOC-1

#### Documentation references
- `guides/core/layouts.md` § Form Layout Options (the new option, written by DOC-1)
- `guides/core/liveview.md` § Built-in Events (the three new FormComponent events, written by DOC-1)
- `guides/customization/styling.md` § Class reference (the three new classes, written by DOC-1)
- `AGENTS.md` § Phoenix / LiveView Rules, § CSS / Assets

#### Implementation details

Layout types: `:form` only (the FormComponent rendered in the index LiveView's modal for the `:new`, `:edit` and `:show_edit` live actions). The `:show` modal keeps its current close behaviour. `:index` and `:show` renderers are otherwise untouched.

Backend boundary: every change is under `lib/aurora_uix/layout/` and `lib/aurora_uix/templates/basic/`; no `Ecto.*` / `Ash.*` reference is added. Dirty state comes from the `"validate"` event, never from inspecting a changeset, so both backends behave the same. The library stays transport-only: nothing here builds a changeset.

State lives in two new keys of the component's `auix` map, both `new` (search `rg -n "_form_dirty?|_discard_confirm_open?" lib test` returns nothing):
- `:_form_dirty?` — `true` once a `"validate"` event reached the component.
- `:_discard_confirm_open?` — `true` while the discard-changes dialog is shown.

Both are reset whenever the parent re-renders the component: `FormGenerator.generate_module/1`'s generated `update/2` replaces `socket.assigns.auix` through `assign(assigns)`, and `FormImpl.auix_update/2` then re-initialises them with `assign_auix_new/3`, the same way it rebuilds `:form`. Dirty state and form data therefore always reset together.

1. **Form layout option** — `lib/aurora_uix/layout/options/form.ex`
   1. Insert this clause directly after the `defp get_default(_assigns, :record_navigator),` clause and before the catch-all `defp get_default(_assigns, option), do: {:not_found, option}`:
      ```elixir
      defp get_default(_assigns, :unsaved_changes_guard_disabled?),
        do: {:ok, false}
      ```
      `Aurora.Uix.Layout.Options.__before_compile__/1` discovers the option from this clause head, so `LayoutOptions.available_options(:form)` returns it and `FormImpl.assign_layout_options/1` stores it at `auix.layout_options.unsaved_changes_guard_disabled?`. Nothing else registers it.
   2. `@moduledoc` — insert after the `:record_navigator` bullet (before the line `For additional option behaviors and rendering details, …`):
      ```
        * `:unsaved_changes_guard_disabled?` - Disables the unsaved-changes guard on the form modal.
          - Accepts a `boolean()`.
          - Default: `false` - Closing the modal with unsaved changes asks the user to confirm.
      ```
2. **`edit_layout` docs** — `lib/aurora_uix/layout/blueprint.ex`, `@doc` of `defmacro edit_layout/3`, `## Options` list: insert directly after the `:new_subtitle` bullet:
   ```
   - `:unsaved_changes_guard_disabled?` (boolean()): When `true`, closing the form modal with unsaved changes closes it without asking for confirmation. Default: `false`.
   ```
3. **Modal component** — `lib/aurora_uix/templates/basic/components/core_components.ex`, `modal/1`:
   1. Insert after `attr(:on_cancel, JS, default: %JS{})`:
      ```elixir
      attr(:hide_on_cancel?, :boolean,
        default: true,
        doc: "when false, a cancel runs only `on_cancel` and the modal stays visible until removed"
      )
      ```
   2. In the `modal(%{host_components: nil} = assigns)` template, replace `data-cancel={JS.exec(@on_cancel, "phx-remove")}` with:
      ```heex
      data-cancel={if @hide_on_cancel?, do: JS.exec(@on_cancel, "phx-remove"), else: @on_cancel}
      ```
   3. In the `@doc` of `modal/1`, append after the `on_cancel={JS.navigate(~p"/posts")}` example block:
      ```
      Set `hide_on_cancel?={false}` when `on_cancel` lets the server decide whether the modal
      closes: the modal then stays visible until the server removes it.
      ```
   The X button (`phx-click={JS.exec("data-cancel", to: "##{@id}")}`), `Esc` (`phx-window-keydown` on the `focus_wrap`) and the click-away (`phx-click-away` on the `focus_wrap`) all execute `data-cancel`, so this one attribute routes all three close paths. The form renders no cancel link (`Actions.Form.set_actions/1` adds only `default_save`), so there is no fourth path.
4. **Index renderer** — `lib/aurora_uix/templates/basic/renderers/index_renderer.ex`, `render/1`:
   1. Replace the opening tag
      ```heex
      <.modal :if={@live_action in [:new, :edit, :show, :show_edit]} id={"auix-#{@auix.module}-#{@live_action}-modal"} show on_cancel={JS.push("auix_route_back")}>
      ```
      with
      ```heex
      <.modal :if={@live_action in [:new, :edit, :show, :show_edit]} id={"auix-#{@auix.module}-#{@live_action}-modal"} show hide_on_cancel?={@live_action == :show} on_cancel={modal_on_cancel(@live_action, @auix)}>
      ```
   2. Under `# PRIVATE`, before `defp entity_id/1`, add:
      ```elixir
      @spec modal_on_cancel(atom(), map()) :: JS.t()
      defp modal_on_cancel(:show, _auix), do: JS.push("auix_route_back")

      defp modal_on_cancel(_live_action, auix),
        do: JS.push("auix_request_close", target: "#auix-#{auix.module}-form")
      ```
      `#auix-#{auix.module}-form` is the `<.simple_form>` id in `FormRenderer.render/1`; the push reaches the FormComponent that owns it.
5. **Form handler** — `lib/aurora_uix/templates/basic/handlers/form_impl.ex`:
   1. `auix_update/2` — in the pipeline, directly after `|> assign_auix_new(:_sections, %{})`, insert:
      ```elixir
      |> assign_auix_new(:_form_dirty?, false)
      |> assign_auix_new(:_discard_confirm_open?, false)
      ```
   2. The generic `auix_handle_event("validate", params, %{assigns: %{auix: auix}} = socket)` clause (the one without `_target`) — replace its last line `{:noreply, assign_auix(socket, :form, form)}` with:
      ```elixir
      {:noreply,
       socket
       |> assign_auix(:form, form)
       |> assign_auix(:_form_dirty?, true)}
      ```
      The toggle-all `"validate"` clause recurses into this clause, so it marks the form dirty too; it is not edited.
   3. Insert these three clauses directly after the `auix_handle_event("auix_download_upload", %{"field" => field}, socket)` clause and before the raising catch-all `auix_handle_event(event, params, _socket)`:
      ```elixir
      def auix_handle_event("auix_request_close", _params, %{assigns: %{auix: auix}} = socket) do
        {:noreply, request_close(socket, auix)}
      end

      def auix_handle_event("auix_keep_editing", _params, socket) do
        {:noreply, assign_auix(socket, :_discard_confirm_open?, false)}
      end

      def auix_handle_event("auix_discard_changes", _params, socket) do
        {:noreply,
         socket
         |> assign_auix(:_discard_confirm_open?, false)
         |> assign_auix(:_form_dirty?, false)
         |> auix_route_back()}
      end
      ```
   4. Under `## PRIVATE`, after `defp do_consume_uploads/3`'s last clause, add:
      ```elixir
      # An open dialog means the request came from `Esc` while it was shown: treat it as "keep editing".
      @spec request_close(Socket.t(), map()) :: Socket.t()
      defp request_close(socket, %{_discard_confirm_open?: true}),
        do: assign_auix(socket, :_discard_confirm_open?, false)

      defp request_close(
             socket,
             %{_form_dirty?: true, layout_options: %{unsaved_changes_guard_disabled?: false}}
           ),
           do: assign_auix(socket, :_discard_confirm_open?, true)

      defp request_close(socket, _auix), do: auix_route_back(socket)
      ```
      `auix_route_back/1` is `Aurora.Uix.Templates.Basic.Helpers.auix_route_back/1`, already imported; it is the same call the existing `"auix_route_back"` clause and the `"save"` success path make.
   5. `@doc` of `auix_handle_event/3` — replace `- \`event\` (binary()) - The event name (e.g., "validate", "save", "switch_section").` with:
      ```
      - `event` (binary()) - The event name (e.g., "validate", "switch_section", "auix_request_close",
        "auix_keep_editing", "auix_discard_changes").
      ```
6. **Form renderer** — `lib/aurora_uix/templates/basic/renderers/form_renderer.ex`:
   1. Add `alias Phoenix.LiveView.JS` directly after `alias Aurora.Uix.Templates.Basic.Renderer`.
   2. In `render/1`, directly after `<div id="portal-target"> </div>` and before the closing `</div>`, insert:
      ```heex
      <.modal :if={@auix._discard_confirm_open?} id={"auix-#{@auix.module}-discard-confirm-modal"} show on_cancel={JS.push("auix_keep_editing", target: @myself)}>
        <div class="auix-discard-confirm">
          <div class="auix-discard-confirm-message">{dt("You have unsaved changes. Discard them and close the form?")}</div>
          <div class="auix-discard-confirm-actions">
            <.button type="button" class="auix-button--alt" name="auix-keep-editing" phx-click="auix_keep_editing" phx-target={@myself}>{dt("Keep editing")}</.button>
            <.button type="button" name="auix-discard-changes" phx-click="auix_discard_changes" phx-target={@myself}>{dt("Discard changes")}</.button>
          </div>
        </div>
      </.modal>
      ```
   3. `@moduledoc` `## Key Features` — add the bullet `- Renders the discard-changes dialog when a form with unsaved changes is closed`.
7. **Theme** — `lib/aurora_uix/templates/basic/themes/base.ex`: insert these three clauses directly after the `def rule(:auix_modal_close_button) do` clause:
   ```elixir
   def rule(:auix_discard_confirm) do
     """
     .auix-discard-confirm {
       display: flex;
       flex-direction: column;
       gap: var(--auix-gap-default);
     }
     """
   end

   def rule(:auix_discard_confirm_message) do
     """
     .auix-discard-confirm-message {
       font-size: var(--auix-font-size-caption);
     }
     """
   end

   def rule(:auix_discard_confirm_actions) do
     """
     .auix-discard-confirm-actions {
       display: flex;
       justify-content: flex-end;
       gap: var(--auix-gap-default);
     }
     """
   end
   ```
   Then run `mix auix.gen.stylesheet`. The generated `assets/css/auix-*.css` files are gitignored; nothing is committed from them.
8. **Routes** — `test/support/app_web/routes.ex`, `load_test_routes/0`: directly after the `RoutesHelper.register_crud(AshCheckboxCheckedTest.Item, "ash-checkbox-checked-items")` call, add:
   ```elixir
   RoutesHelper.register_crud(
     FormDiscardGuardTest.Product,
     "form-discard-guard-products"
   )

   RoutesHelper.register_crud(
     AshFormDiscardGuardTest.Author,
     "ash-form-discard-guard-authors"
   )

   RoutesHelper.register_crud(
     FormDiscardGuardDisabledTest.Product,
     "form-discard-guard-disabled-products"
   )
   ```

##### Acceptance criteria
- [ ] AC-1: Given the default guard, on `/form-discard-guard-products/:id/edit` the modal root `#auix-product-edit-modal` carries a `data-cancel` that pushes `auix_request_close` and never runs `phx-remove`; on `/form-discard-guard-products/:id/show` the modal `#auix-product-show-modal` keeps a `data-cancel` that pushes `auix_route_back`
- [ ] AC-2: Given an edit form without changes, `auix_request_close` closes the modal (`#auix-product-edit-modal` gone) and no discard dialog appears
- [ ] AC-3: Given an edit form after a `"validate"` change, `auix_request_close` keeps `#auix-product-edit-modal` open and shows `#auix-product-discard-confirm-modal` with `button[name='auix-keep-editing']` and `button[name='auix-discard-changes']`
- [ ] AC-4: Clicking `button[name='auix-keep-editing']` removes the dialog, keeps the edit modal open, and the changed value stays in `input[name='product[name]']`
- [ ] AC-5: Clicking `button[name='auix-discard-changes']` closes the edit modal and the stored product keeps its original name
- [ ] AC-6 (degraded path — `Esc` while the dialog is shown): `auix_request_close` with the dialog open removes the dialog and keeps the edit modal open
- [ ] AC-7: Given the `:new` route with a `"validate"` change, `auix_request_close` shows `#auix-product-discard-confirm-modal`
- [ ] AC-8: Given an Ash resource (`Aurora.Uix.Guides.Blog.Author`) on `/ash-form-discard-guard-authors/:id/edit`, a clean form closes on `auix_request_close`; a changed form shows `#auix-author-discard-confirm-modal`, and `auix-discard-changes` closes the modal leaving the stored author's name unchanged
- [ ] AC-9: Given `edit_layout :product, unsaved_changes_guard_disabled?: true`, a changed form closes on `auix_request_close` without showing the dialog
- [ ] AC-10: The three `auix-discard-confirm*` rules are emitted by the stylesheet generator (mechanical — no red test; verified by `mix auix.gen.stylesheet && grep -c -E '\.auix-discard-confirm(-message|-actions)? *\{' assets/css/auix-rules.css` printing `3`)
- [ ] AC-11: The X button, `Esc` and click-away still close a clean form modal in a real browser (manual — no red test; verified by the existing Wallaby features `"Test new fallback "`, `"Test show-edit fallback "` and `"Test edit fallback "` in `test/browser_cases/create_ui_default_layout_test.exs`, which click `.auix-modal-close-button` on a clean form and must stay green unmodified)

##### Test ports
- Route `"/form-discard-guard-products"` registered in `routes.ex` via `register_crud/2` (step 8) · layout types `:form`, `:show` · observable: `has_element?/2` on `#auix-product-edit-modal`, `#auix-product-discard-confirm-modal`, `button[name='auix-keep-editing']`, `button[name='auix-discard-changes']`, `input[name='product[name]']`
- Route `"/ash-form-discard-guard-authors"` registered via `register_crud/2` (step 8) · layout type `:form` · observable: `has_element?/2` on `#auix-author-edit-modal`, `#auix-author-discard-confirm-modal`
- Route `"/form-discard-guard-disabled-products"` registered via `register_crud/2` (step 8) · layout type `:form` · observable: `has_element?/2` on `#auix-product-edit-modal`, `#auix-product-discard-confirm-modal`
- Close requests are driven with `view |> with_target("#auix-<module>-form") |> render_click("auix_request_close", %{})`. LiveViewTest executes only `push`/`patch`/`navigate` JS commands and skips `exec`, so clicking the × button does nothing under LiveViewTest; AC-1 proves the `data-cancel` wiring that all three browser paths execute, AC-11 proves it in a real browser.

##### Red tests
All three test files are new: `ls test/cases_live | grep -i discard` and `rg -n "discard|unsaved" -i test` return nothing.

| AC | Placement | Setup | Test file | Test name | Assertion sketch |
|---|---|---|---|---|---|
| AC-1 | new file | `use Aurora.UixWeb.Test.UICase, :phoenix_case` + `use Aurora.UixWeb.Test.WebCase, :aurora_uix_for_test`; `auix_resource_metadata(:product, context: Inventory, schema: Product)`; `auix_create_ui do edit_layout :product do stacked([:reference, :name, :quantity_initial]) end end`; `seed/0` = `delete_all_inventory_data()` then `1 \|> create_sample_products(:test) \|> get_in([Access.key!("id_test-1"), Access.key!(:id)])` | `test/cases_live/form_discard_guard_test.exs` (module `Aurora.UixWeb.Test.FormDiscardGuardTest`) | `"form modal cancel asks the form component; show modal routes back"` | `assert has_element?(view, "#auix-product-edit-modal[data-cancel*='auix_request_close']")`; `refute has_element?(view, "#auix-product-edit-modal[data-cancel*='phx-remove']")`; on a second `live/2` of `.../#{id}/show`: `assert has_element?(show_view, "#auix-product-show-modal[data-cancel*='auix_route_back']")` |
| AC-2 | same file | as AC-1; `live(conn, "/form-discard-guard-products/#{id}/edit")` | same | `"a clean form closes without a prompt"` | `view \|> with_target("#auix-product-form") \|> render_click("auix_request_close", %{})`; `refute has_element?(view, "#auix-product-edit-modal")`; `refute has_element?(view, "#auix-product-discard-confirm-modal")` |
| AC-3 | same file | as AC-2, then `view \|> form("#auix-product-form", product: %{name: "Changed name"}) \|> render_change()` | same | `"a changed form opens the discard dialog"` | after `auix_request_close`: `assert has_element?(view, "#auix-product-edit-modal")`; `assert has_element?(view, "#auix-product-discard-confirm-modal button[name='auix-keep-editing']")`; `assert has_element?(view, "#auix-product-discard-confirm-modal button[name='auix-discard-changes']")` |
| AC-4 | same file | as AC-3 | same | `"keep editing closes the dialog and keeps the changes"` | `view \|> element("button[name='auix-keep-editing']") \|> render_click()`; `refute has_element?(view, "#auix-product-discard-confirm-modal")`; `assert has_element?(view, "#auix-product-edit-modal input[name='product[name]'][value='Changed name']")` |
| AC-5 | same file | as AC-3 | same | `"discard changes closes the modal without saving"` | `view \|> element("button[name='auix-discard-changes']") \|> render_click()`; `refute has_element?(view, "#auix-product-edit-modal")`; `assert Inventory.get_product!(id).name == "Item test-1"` |
| AC-6 | same file | as AC-3 | same | `"a close request while the dialog is open keeps editing"` | second `auix_request_close`; `refute has_element?(view, "#auix-product-discard-confirm-modal")`; `assert has_element?(view, "#auix-product-edit-modal")` |
| AC-7 | same file | `delete_all_inventory_data()`; `live(conn, "/form-discard-guard-products/new")`; `form("#auix-product-form", product: %{name: "Brand new"}) \|> render_change()` | same | `"a changed new form opens the discard dialog"` | after `auix_request_close`: `assert has_element?(view, "#auix-product-new-modal")`; `assert has_element?(view, "#auix-product-discard-confirm-modal")` |
| AC-8 | new file | `use` lines as AC-1; `alias Aurora.Uix.Guides.Blog.Author`; `auix_resource_metadata(:author, ash_resource: Author)`; `auix_create_ui do edit_layout :author do stacked([:name, :email, :bio]) end end`; `seed/0` = `delete_all_blog_data()` then `1 \|> create_sample_authors() \|> List.first()`; `live(conn, "/ash-form-discard-guard-authors/#{author.id}/edit")` | `test/cases_live/ash_form_discard_guard_test.exs` (module `Aurora.UixWeb.Test.AshFormDiscardGuardTest`) | `"a clean form closes without a prompt"`; `"discard changes closes the modal without saving"` | clean: after `with_target("#auix-author-form") \|> render_click("auix_request_close", %{})`, `refute has_element?(view, "#auix-author-edit-modal")`. Changed: `form("#auix-author-form", author: %{name: "Changed author"}) \|> render_change()`, `auix_request_close`, `assert has_element?(view, "#auix-author-discard-confirm-modal")`, click `button[name='auix-discard-changes']`, `refute has_element?(view, "#auix-author-edit-modal")`, `assert Ash.get!(Author, author.id).name == author.name` |
| AC-9 | new file | `use` lines as AC-1; `auix_resource_metadata(:product, context: Inventory, schema: Product)`; `auix_create_ui do edit_layout :product, unsaved_changes_guard_disabled?: true do stacked([:reference, :name, :quantity_initial]) end end`; seed as AC-1; `live(conn, "/form-discard-guard-disabled-products/#{id}/edit")`; `form("#auix-product-form", product: %{name: "Changed name"}) \|> render_change()` | `test/cases_live/form_discard_guard_disabled_test.exs` (module `Aurora.UixWeb.Test.FormDiscardGuardDisabledTest`) | `"a changed form closes without a prompt when the guard is disabled"` | after `auix_request_close`: `refute has_element?(view, "#auix-product-discard-confirm-modal")`; `refute has_element?(view, "#auix-product-edit-modal")` |

##### Markup changes and the tests that drive them
- `modal/1`'s `data-cancel` changes for the `:new`, `:edit` and `:show_edit` modals. `rg -n "data-cancel|auix_route_back|modal-close-button" test` hits only `test/browser_cases/create_ui_default_layout_test.exs` (`close_modal_button/1`, four features) and the embeds-many add-modal close selectors in `test/browser_cases/embeds_many_test.exs` and `test/browser_cases/ash_embeds_test.exs`. The create-ui features click × on a clean form: new drive is unchanged, the clean form routes back through `auix_request_close`. The embeds-many selectors target the embeds-many add modal, whose `on_cancel` is unchanged.
- The modal ids `auix-<module>-<live_action>-modal` and the form id `auix-<module>-form` are unchanged; every `test/cases_live` test using them keeps its drive.

##### Modules & components
1. `Aurora.Uix.Layout.Options.Form` at `lib/aurora_uix/layout/options/form.ex` — modified (step 1)
2. `Aurora.Uix.Layout.Blueprint` at `lib/aurora_uix/layout/blueprint.ex` — `@doc` only (step 2)
3. Components: `modal/1` in `core_components.ex` extended with attr `hide_on_cancel?` (`:boolean`, optional, default `true`); existing attrs `id`, `show`, `on_cancel` relied on. `button/1` reused with attrs `type`, `class` and the global `name`, `phx-click`, `phx-target`. No new component, no LiveComponent.
4. `Aurora.Uix.Templates.Basic.Renderers.IndexRenderer` — modified (step 4); `FormRenderer` — modified (step 6); `Aurora.Uix.Templates.Basic.Handlers.FormImpl` — modified (step 5). No `default_renderer.ex` dispatch change.
5. Theme: `.auix-discard-confirm` ← `rule(:auix_discard_confirm)`, `.auix-discard-confirm-message` ← `rule(:auix_discard_confirm_message)`, `.auix-discard-confirm-actions` ← `rule(:auix_discard_confirm_actions)` in `themes/base.ex`; regenerate with `mix auix.gen.stylesheet`. No new `hero-*` icon, so `mix auix.gen.tailwind_classes` output is unchanged.
6. `dt/1` strings: `"You have unsaved changes. Discard them and close the form?"`, `"Keep editing"`, `"Discard changes"`.

##### Green tests
1. The red tests above pass, unmodified (code-issue runs these, targeted)
2. `mix test` — full suite green (review-issue runs this; code-issue runs
   only this section's test files)
3. `mix compile --warnings-as-errors` clean
<!-- section:UI-1:end -->

---

### Out of Scope
- The form renders no cancel link today, so there is none to guard; the three close paths are ×, `Esc` and click-away.
- Leaving the form through the record navigator bar (previous / next record), browser back, a page reload, closing the tab: no `beforeunload` prompt is added.
- Changes typed inside a nested embeds-many add modal that were not yet applied to the parent form do not mark the form dirty.
- The `:show` modal and the show component keep their current close behaviour.
- Form data and dirty state are both reset when the parent LiveView re-renders the form component; that reset predates this issue and is unchanged.
<!-- enriched-spec:end -->
