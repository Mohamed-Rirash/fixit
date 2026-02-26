defmodule Fixit.Workspaces.Project do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "projects" do
    field :name, :string
    field :project_key, :string
    field :description, :string
    field :user_id, :binary_id
    belongs_to :organization, Fixit.Workspaces.Organization, type: :binary_id
    belongs_to :team, Fixit.Workspaces.Team, type: :binary_id
    has_many :memberships, Fixit.Workspaces.ProjectMembership

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(project, attrs, user_scope) do
    project
    |> cast(attrs, [:name, :project_key, :description, :organization_id, :team_id])
    |> validate_required([:name, :project_key, :description, :organization_id, :team_id])
    |> validate_format(:project_key, ~r/^[A-Z0-9_]+$/,
      message: "must be uppercase letters, numbers, and underscores"
    )
    |> foreign_key_constraint(:organization_id)
    |> foreign_key_constraint(:team_id)
    |> unique_constraint(:project_key, name: :projects_user_id_project_key_index)
    |> put_change(:user_id, user_scope.user.id)
  end
end
