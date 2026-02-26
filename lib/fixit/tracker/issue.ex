defmodule Fixit.Tracker.Issue do
  use Ecto.Schema
  import Ecto.Changeset

  @methods ~w(GET POST PUT PATCH DELETE)
  @statuses ~w(open in_progress resolved)

  def methods, do: @methods
  def statuses, do: @statuses

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "issues" do
    field :path, :string
    field :method, :string
    field :status, :string
    field :error_code, :integer
    field :description, :string
    field :payload, :string
    field :error_response, :string
    field :headers, :string
    field :stack_trace, :string
    field :user_id, :binary_id
    belongs_to :organization, Fixit.Workspaces.Organization, type: :binary_id
    field :project_id, :binary_id
    field :claimed_by_id, :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(issue, attrs, user_scope) do
    issue
    |> cast(attrs, [
      :path,
      :method,
      :status,
      :error_code,
      :description,
      :payload,
      :error_response,
      :headers,
      :stack_trace,
      :organization_id,
      :project_id,
      :claimed_by_id
    ])
    |> validate_required([
      :path,
      :method,
      :status,
      :error_code,
      :description,
      :payload,
      :error_response,
      :organization_id,
      :project_id
    ])
    |> validate_inclusion(:method, @methods)
    |> validate_inclusion(:status, @statuses)
    |> validate_length(:path, max: 255)
    |> validate_format(:path, ~r|^/|, message: "must start with /")
    |> validate_number(:error_code, greater_than_or_equal_to: 100, less_than: 600)
    |> foreign_key_constraint(:organization_id)
    |> put_change(:user_id, user_scope.user.id)
  end
end
