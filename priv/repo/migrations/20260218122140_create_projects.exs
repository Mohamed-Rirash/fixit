defmodule Fixit.Repo.Migrations.CreateProjects do
  use Ecto.Migration

  def change do
    create table(:projects, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :project_key, :string, null: false
      add :description, :text, null: false

      add :organization_id, references(:organizations, on_delete: :delete_all, type: :binary_id),
        null: false

      add :team_id, references(:teams, on_delete: :delete_all, type: :binary_id), null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:projects, [:user_id])
    create index(:projects, [:organization_id])
    create index(:projects, [:team_id])
    create unique_index(:projects, [:user_id, :project_key])
  end
end
