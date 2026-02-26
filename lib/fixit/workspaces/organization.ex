defmodule Fixit.Workspaces.Organization do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "organizations" do
    field :name, :string
    field :slug, :string
    field :user_id, :binary_id
    has_many :teams, Fixit.Workspaces.Team
    has_many :projects, Fixit.Workspaces.Project
    has_many :memberships, Fixit.Workspaces.OrganizationMembership

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(organization, attrs, user_scope) do
    organization
    |> cast(attrs, [:name, :slug])
    |> validate_required([:name, :slug])
    |> validate_format(:slug, ~r/^[a-z0-9-]+$/,
      message: "must be lowercase letters, numbers, and dashes"
    )
    |> unique_constraint(:slug, name: :organizations_user_id_slug_index)
    |> put_change(:user_id, user_scope.user.id)
  end
end
