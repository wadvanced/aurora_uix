defmodule Aurora.Uix.Test.Cases.UnconstrainedAtomWarningTest.Ticket do
  use Ash.Resource, data_layer: Ash.DataLayer.Ets, domain: nil

  attributes do
    uuid_primary_key :id
    attribute :title, :string, public?: true
    attribute :state, :atom, public?: true
  end

  actions do
    default_accept [:title, :state]
    defaults [:read, :destroy, :update, :create]
  end

  calculations do
    calculate :state_copy, :atom, expr(state)
  end
end

defmodule Aurora.Uix.Test.Cases.UnconstrainedAtomWarningTest do
  # Not async: the views modules compile in a process of their own, so the warning is captured
  # only by raising the global Logger level, which the test environment keeps at `:error`.
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  @ticket "auix_resource_metadata :ticket, ash_resource: #{inspect(__MODULE__)}.Ticket"

  setup do
    level = Logger.level()
    Logger.configure(level: :warning)
    on_exit(fn -> Logger.configure(level: level) end)
  end

  test "an atom without one_of warns when a form places it and can write it" do
    log =
      ticket_log("""
        #{@ticket}

        auix_create_ui do
          edit_layout :ticket do
            stacked [:title, :state, :state_copy]
          end
        end
      """)

    assert log =~ "Field :state of resource :ticket"
    assert log =~ "without a :one_of constraint"
    refute log =~ ":state_copy"
  end

  test "the metadata alone does not warn, nor does an index that places the field" do
    assert ticket_log(@ticket) == ""

    assert ticket_log("""
             #{@ticket}

             auix_create_ui do
               index_columns :ticket, [:title, :state]

               edit_layout :ticket do
                 stacked [:title]
               end
             end
           """) == ""
  end

  test "a read-only field does not warn, declared in the metadata or in the layout" do
    assert ticket_log("""
             auix_resource_metadata :ticket do
               ash_resource #{inspect(__MODULE__)}.Ticket
               field :state, readonly: true
             end

             auix_create_ui do
               edit_layout :ticket do
                 stacked [:title, :state]
               end
             end
           """) == ""

    assert ticket_log("""
             #{@ticket}

             auix_create_ui do
               edit_layout :ticket do
                 stacked [:title, state: [readonly: true]]
               end
             end
           """) == ""
  end

  test "a resource without a generated form does not warn" do
    assert ticket_log("""
             #{@ticket}

             auix_create_ui generate: [:index_component] do
               edit_layout :ticket do
                 stacked [:state]
               end
             end
           """) == ""
  end

  # The log lines about the atom, of a views module compiled with `body`.
  @spec ticket_log(binary()) :: binary()
  defp ticket_log(body) do
    fn ->
      Code.compile_string("""
      defmodule Aurora.UixWeb.Test.UnconstrainedAtomSample#{System.unique_integer([:positive])} do
        use Aurora.Uix

      #{body}
      end
      """)
    end
    |> capture_log()
    |> String.split("\n")
    |> Enum.filter(&(&1 =~ "one_of"))
    |> Enum.join("\n")
  end
end
