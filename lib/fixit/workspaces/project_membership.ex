defmodule Fixit.Workspaces.ProjectMembership do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "project_memberships" do
    field :role, :string
    belongs_to :project, Fixit.Workspaces.Project
    belongs_to :user, Fixit.Accounts.User
    belongs_to :invited_by, Fixit.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(membership, attrs) do
    membership
    |> cast(attrs, [:role, :project_id, :user_id, :invited_by_id])
    |> validate_required([:role, :project_id, :user_id])
    |> validate_inclusion(:role, ["admin", "collaborator"])
    |> unique_constraint([:project_id, :user_id])
  end
end
