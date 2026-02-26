defmodule Fixit.Repo.Migrations.AddIssueOrganizationScope do
  use Ecto.Migration

  def up do
    alter table(:issues) do
      add :organization_id, references(:organizations, type: :binary_id, on_delete: :delete_all)
    end

    execute("""
    UPDATE issues
    SET organization_id = projects.organization_id
    FROM projects
    WHERE issues.project_id = projects.id
    """)

    create index(:issues, [:organization_id])
    create index(:issues, [:organization_id, :project_id])
  end

  def down do
    drop_if_exists index(:issues, [:organization_id, :project_id])
    drop_if_exists index(:issues, [:organization_id])

    alter table(:issues) do
      remove :organization_id
    end
  end
end
