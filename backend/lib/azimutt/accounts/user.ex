defmodule Azimutt.Accounts.User do
  @moduledoc "User schema"
  use Ecto.Schema
  use Azimutt.Schema
  import Ecto.Changeset
  alias Azimutt.Accounts.User
  alias Azimutt.Organizations.Organization
  alias Azimutt.Organizations.OrganizationMember
  alias Azimutt.Utils.Slugme

  schema "users" do
    field :slug, :string
    field :name, :string
    field :email, :string
    field :provider, :string
    field :provider_uid, :string
    field :avatar, :string
    field :company, :string
    field :location, :string
    field :description, :string
    field :github_username, :string
    field :twitter_username, :string
    field :is_admin, :boolean, default: false
    field :hashed_password, :string, redact: true
    field :password, :string, virtual: true, redact: true
    field :last_signin, :utc_datetime_usec
    embeds_one :data, User.Data, on_replace: :update
    timestamps()
    field :confirmed_at, :utc_datetime_usec
    field :deleted_at, :utc_datetime_usec

    many_to_many :organizations, Organization, join_through: OrganizationMember
  end

  def search_fields, do: [:slug, :name, :email, :company, :location, :description, :github_username, :twitter_username]

  @doc """
  A user changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_creation_changeset(user, attrs, now, opts \\ []) do
    required = [:name, :email, :avatar]

    user
    |> cast(attrs, required ++ [:password, :company, :location, :description, :github_username, :twitter_username])
    |> Slugme.generate_slug(:name)
    |> validate_email()
    |> validate_password(opts)
    |> put_change(:last_signin, now)
    |> validate_required(required)
  end

  def github_creation_changeset(user, attrs, now) do
    required = [:name, :email, :avatar, :provider]

    user
    |> cast(attrs, required ++ [:provider_uid, :company, :location, :description, :github_username, :twitter_username])
    |> Slugme.generate_slug(:github_username)
    |> put_change(:last_signin, now)
    |> validate_required(required)
  end

  def heroku_creation_changeset(user, attrs, now) do
    required = [:name, :email, :avatar, :provider]

    user
    |> cast(attrs, required)
    |> Slugme.generate_slug(:name)
    |> put_change(:last_signin, now)
    |> validate_required(required)
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> unsafe_validate_unique(:email, Azimutt.Repo)
    |> unique_constraint(:email)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72)
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # If using Bcrypt, then further validate it is at most 72 bytes long
      |> validate_length(:password, max: 72, count: :bytes)
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  @doc """
  A user changeset for changing the email.

  It requires the email to change otherwise an error is added.
  """
  def email_changeset(user, attrs) do
    user
    |> cast(attrs, [:email])
    |> validate_email()
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  @doc """
  A user changeset for changing the password.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user, now) do
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%Azimutt.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end
end
