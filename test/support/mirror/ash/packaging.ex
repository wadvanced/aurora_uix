defmodule Aurora.Uix.Test.MirrorAsh.Packaging do
  @moduledoc false

  use Ash.Resource, data_layer: :embedded

  attributes do
    attribute :material, :atom, constraints: [one_of: [:box, :bag, :crate]], public?: true
    attribute :fragile, :boolean, public?: true
    attribute :notes, :string, public?: true
  end
end
