defmodule Aurora.Uix.Test.Accounts.User do
  @moduledoc """
  Ecto schema for test users in the Aurora.Uix application.

  Includes fields for user information and an embedded profile.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Aurora.Uix.Test.Accounts.User

  @doc """
  Defines the `users` table schema.

  Fields:
    - full_name: User's full name.
    - email: User's email address.
    - avatar_url: URL to user's avatar image.
    - confirmed_at: Timestamp when the user was confirmed.
    - profile: Embedded profile with online status, dark mode, and visibility.
  """
  schema "users" do
    field(:full_name, :string)
    field(:email, :string)
    field(:avatar_url, :string)
    field(:confirmed_at, :naive_datetime)

    embeds_one :profile, Profile do
      field(:online, :boolean)
      field(:dark_mode, :boolean)
      field(:visibility, Ecto.Enum, values: [:public, :private, :friends_only])
    end

    timestamps()
  end

  @doc """
  Builds a changeset for a user.

  Casts `:full_name` and `:email` fields and requires an embedded profile.
  """
  @spec changeset(User.t(), map()) :: Ecto.Changeset.t()
  def changeset(%User{} = user, attrs \\ %{}) do
    user
    |> cast(attrs, [:full_name, :email])
    |> cast_embed(:profile, required: true, with: &profile_changeset/2)
  end

  @doc """
  Builds a changeset for the embedded profile.

  Casts `:online`, `:dark_mode`, and `:visibility` fields.
  Requires `:online` and `:visibility`.
  """

  @spec profile_changeset(Profile.t(), map()) :: Ecto.Changeset.t()
  def profile_changeset(profile, attrs \\ %{}) do
    profile
    |> cast(attrs, [:online, :dark_mode, :visibility])
    |> validate_required([:online, :visibility])
  end
end
