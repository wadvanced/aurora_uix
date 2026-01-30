defmodule Aurora.Uix.Guides.Accounts.User do
  @moduledoc """
  Ecto schema for test users in guides and examples.

  Represents a user with personal information, embedded profile settings, and email addresses.

  ## Key Features

  - Personal information fields (given_name, family_name, avatar_url)
  - Embedded profile with online status, dark mode, and visibility settings
  - Embedded emails collection for multiple email addresses
  - Confirmation timestamp tracking

  ## Key Constraints

  - Only for guides and test scenarios
  - Requires given_name and profile
  - Profile requires online status and visibility
  - Email addresses must be valid format
  - Visibility must be one of: `:public`, `:private`, `:friends_only`
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Aurora.Uix.Guides.Accounts.User

  @type t :: %__MODULE__{
          id: Ecto.UUID.t(),
          given_name: binary() | nil,
          family_name: binary() | nil,
          avatar_url: binary() | nil,
          confirmed_at: NaiveDateTime.t() | nil,
          profile: Ecto.Schema.t() | nil,
          emails: Ecto.Schema.t() | nil,
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }
  schema "users" do
    field(:given_name, :string)
    field(:family_name, :string)
    field(:avatar_url, :string)
    field(:confirmed_at, :naive_datetime)

    embeds_one :profile, Profile do
      field(:online, :boolean)
      field(:dark_mode, :boolean)
      field(:visibility, Ecto.Enum, values: [:public, :private, :friends_only])
    end

    embeds_many :emails, Email, on_replace: :delete do
      field(:email, :string)
      field(:name, :string)
    end

    timestamps()
  end

  @doc """
  Builds a changeset for a user.

  ## Parameters
  - `user` (User.t()) - The user struct.
  - `attrs` (map()) - Attributes to update. Defaults to `%{}`.

  ## Returns
  Ecto.Changeset.t() - The changeset for the user.
  """
  @spec changeset(User.t(), map()) :: Ecto.Changeset.t()
  def changeset(%User{} = user, attrs \\ %{}) do
    user
    |> cast(attrs, [:given_name, :family_name, :avatar_url, :confirmed_at])
    |> validate_required([:given_name])
    |> cast_embed(:profile, required: true, with: &profile_changeset/2)
    |> cast_embed(:emails, with: &email_changeset/2)
  end

  @doc """
  Builds a changeset for the embedded profile.

  ## Parameters
  - `profile` (Ecto.Schema.t()) - The profile struct.
  - `attrs` (map()) - Attributes to update. Defaults to `%{}`.

  ## Returns
  Ecto.Changeset.t() - The changeset for the profile.
  """
  @spec profile_changeset(Ecto.Schema.t(), map()) :: Ecto.Changeset.t()
  def profile_changeset(profile, attrs \\ %{}) do
    profile
    |> cast(attrs, [:online, :dark_mode, :visibility])
    |> validate_required([:online, :visibility])
  end

  @doc """
  Builds a changeset for each embedded email.

  ## Parameters
  - `email` (Ecto.Schema.t()) - The email struct.
  - `attrs` (map()) - Attributes to update. Defaults to `%{}`.

  ## Returns
  Ecto.Changeset.t() - The changeset for the email.
  """
  @spec email_changeset(Ecto.Schema.t(), map()) :: Ecto.Changeset.t()
  def email_changeset(email, attrs \\ %{}) do
    email
    |> cast(attrs, [:email, :name])
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email address")

    # |> unique_constraint(:email)
  end
end
