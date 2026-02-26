defmodule Fixit.Workspaces.Team do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "teams" do
    field :name, :string
    field :role, :string
    field :user_id, :binary_id
    belongs_to :organization, Fixit.Workspaces.Organization, type: :binary_id
    has_many :projects, Fixit.Workspaces.Project

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(team, attrs, user_scope) do
    team
    |> cast(attrs, [:name, :role, :organization_id])
    |> validate_required([:name, :role, :organization_id])
    |> validate_inclusion(:role, ~w(frontend backend fullstack qa devops))
    |> foreign_key_constraint(:organization_id)
    |> put_change(:user_id, user_scope.user.id)
  end
end
