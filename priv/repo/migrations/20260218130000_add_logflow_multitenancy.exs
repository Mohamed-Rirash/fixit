defmodule Fixit.Repo.Migrations.AddLogflowMultitenancy do
  use Ecto.Migration

  def change do
    create table(:organization_memberships, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :role, :string, null: false, default: "member"

      add :organization_id, references(:organizations, type: :binary_id, on_delete: :delete_all),
        null: false

      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:organization_memberships, [:organization_id, :user_id])
    create index(:organization_memberships, [:user_id])

    create table(:project_memberships, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :role, :string, null: false, default: "collaborator"

      add :project_id, references(:projects, type: :binary_id, on_delete: :delete_all),
        null: false

      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :invited_by_id, references(:users, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:project_memberships, [:project_id, :user_id])
    create index(:project_memberships, [:user_id])

    alter table(:issues) do
      add :project_id, references(:projects, type: :binary_id, on_delete: :delete_all)
      add :headers, :text
      add :stack_trace, :text
      add :claimed_by_id, references(:users, type: :binary_id, on_delete: :nilify_all)
    end

    create index(:issues, [:project_id])
    create index(:issues, [:claimed_by_id])
  end
end
