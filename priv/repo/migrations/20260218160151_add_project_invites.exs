defmodule Fixit.Repo.Migrations.AddProjectInvites do
  use Ecto.Migration

  def change do
    create table(:project_invites, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :string, null: false
      add :role, :string, null: false, default: "collaborator"
      add :token_hash, :binary, null: false
      add :accepted_at, :utc_datetime

      add :project_id, references(:projects, type: :binary_id, on_delete: :delete_all),
        null: false

      add :invited_by_id, references(:users, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:project_invites, [:token_hash])
    create index(:project_invites, [:email])
    create index(:project_invites, [:project_id])
  end
end
