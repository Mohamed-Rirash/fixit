defmodule Fixit.Workspaces.ProjectInvite do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "project_invites" do
    field :email, :string
    field :role, :string
    field :token_hash, :binary
    field :accepted_at, :utc_datetime
    belongs_to :project, Fixit.Workspaces.Project
    belongs_to :invited_by, Fixit.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(invite, attrs) do
    invite
    |> cast(attrs, [:email, :role, :token_hash, :accepted_at, :project_id, :invited_by_id])
    |> validate_required([:email, :role, :token_hash, :project_id])
    |> validate_inclusion(:role, ["admin", "collaborator"])
    |> validate_format(:email, ~r/^[^@,;\s]+@[^@,;\s]+$/, message: "must be a valid email")
    |> unique_constraint(:token_hash)
  end
end
