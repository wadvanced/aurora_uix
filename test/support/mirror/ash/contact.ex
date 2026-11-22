defmodule Aurora.Uix.Test.MirrorAsh.Contact do
  @moduledoc false

  use Ash.Resource, data_layer: :embedded

  attributes do
    attribute :email, :string, allow_nil?: false, public?: true
    attribute :name, :string, public?: true
  end

  validations do
    validate match(:email, "^[^\\s]+@[^\\s]+$"), message: "must be a valid email address"
  end
end
