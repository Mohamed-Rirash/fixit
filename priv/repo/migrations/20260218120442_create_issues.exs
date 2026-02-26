defmodule Fixit.Repo.Migrations.CreateIssues do
  use Ecto.Migration

  def change do
    create table(:issues, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :path, :string, null: false
      add :method, :string, null: false
      add :status, :string, null: false, default: "open"
      add :error_code, :integer, null: false
      add :description, :text, null: false
      add :payload, :text, null: false
      add :error_response, :text, null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:issues, [:user_id])
    create index(:issues, [:user_id, :status])
  end
end
