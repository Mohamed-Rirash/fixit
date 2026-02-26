defmodule Fixit.Workspaces.OrganizationMembership do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "organization_memberships" do
    field :role, :string
    belongs_to :organization, Fixit.Workspaces.Organization
    belongs_to :user, Fixit.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(membership, attrs) do
    membership
    |> cast(attrs, [:role, :organization_id, :user_id])
    |> validate_required([:role, :organization_id, :user_id])
    |> validate_inclusion(:role, ["owner", "member"])
    |> unique_constraint([:organization_id, :user_id])
  end
end
