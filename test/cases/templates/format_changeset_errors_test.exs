defmodule Aurora.Uix.Test.FormatChangesetErrorsTest do
  use ExUnit.Case, async: true

  alias Aurora.Uix.Templates.Basic.Helpers

  @spec changeset(keyword(), map(), map()) :: Ecto.Changeset.t()
  defp changeset(errors, changes \\ %{}, types \\ %{}) do
    %Ecto.Changeset{valid?: false, data: %{}, types: types, changes: changes, errors: errors}
  end

  test "format_changeset_errors lists every error, nested and repeated ones included" do
    plain = [name: {"can't be blank", []}] |> changeset() |> Helpers.format_changeset_errors()
    assert ["name: can't be blank"] = plain

    repeated =
      [name: {"first", []}, name: {"second", []}]
      |> changeset()
      |> Helpers.format_changeset_errors()
      |> Enum.sort()

    assert ["name: first", "name: second"] = repeated

    one =
      changeset(
        [],
        %{product_barcode: changeset([{:code, {"can't be blank", []}}])},
        %{product_barcode: {:assoc, %{cardinality: :one}}}
      )

    one_errors = Helpers.format_changeset_errors(one)
    assert ["product_barcode.code: can't be blank"] = one_errors

    many =
      changeset(
        [],
        %{
          contacts: [
            %{changeset([]) | valid?: true},
            changeset(email: {"must be a valid email address", []})
          ]
        },
        %{contacts: {:assoc, %{cardinality: :many}}}
      )

    many_errors = Helpers.format_changeset_errors(many)
    assert ["contacts.email: must be a valid email address"] = many_errors
  end
end
