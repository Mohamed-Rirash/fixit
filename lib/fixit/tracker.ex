defmodule Fixit.Tracker do
  @moduledoc """
  The Tracker context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Changeset
  alias Fixit.Accounts.Scope
  alias Fixit.Repo
  alias Fixit.Tracker.Issue
  alias Fixit.Workspaces
  alias Fixit.Workspaces.Project

  def subscribe_issues(%Scope{} = scope) do
    Workspaces.list_projects(scope)
    |> Enum.each(fn project ->
      Phoenix.PubSub.subscribe(Fixit.PubSub, "project:#{project.id}:issues")
    end)
  end

  defp broadcast_issue(issue, message) do
    Phoenix.PubSub.broadcast(Fixit.PubSub, "project:#{issue.project_id}:issues", message)
  end

  def list_issues(%Scope{} = scope), do: list_issues(scope, %{})

  def list_issues(%Scope{} = scope, filters) when is_map(filters) do
    status = Map.get(filters, "status", "all")
    organization_id = Map.get(filters, "organization_id", "all")
    project_id = Map.get(filters, "project_id", "all")
    project_ids = Workspaces.list_projects(scope) |> Enum.map(& &1.id)

    Issue
    |> where([i], i.project_id in ^project_ids)
    |> maybe_filter_status(status)
    |> maybe_filter_organization(organization_id)
    |> maybe_filter_project(project_id)
    |> order_by([i], desc: i.inserted_at)
    |> Repo.all()
  end

  def get_issue!(%Scope{} = scope, id) do
    issue = Repo.get!(Issue, id) |> Repo.preload(:organization)

    if Workspaces.project_member?(scope, issue.project_id) do
      issue
    else
      raise Ecto.NoResultsError, queryable: Issue
    end
  end

  def create_issue(%Scope{} = scope, attrs) do
    case validate_issue_scope(scope, attrs) do
      :ok ->
        with {:ok, issue = %Issue{}} <-
               %Issue{}
               |> Issue.changeset(attrs, scope)
               |> Repo.insert() do
          broadcast_issue(issue, {:created, issue})
          {:ok, issue}
        end

      {:error, field} ->
        {:error,
         %Issue{}
         |> Issue.changeset(attrs, scope)
         |> Changeset.add_error(field, "is invalid")}
    end
  end

  def update_issue(%Scope{} = scope, %Issue{} = issue, attrs) do
    true = Workspaces.project_member?(scope, issue.project_id)

    case validate_issue_scope(scope, attrs, issue) do
      :ok ->
        with {:ok, issue = %Issue{}} <-
               issue
               |> Issue.changeset(attrs, scope)
               |> Repo.update() do
          broadcast_issue(issue, {:updated, issue})
          {:ok, issue}
        end

      {:error, field} ->
        {:error,
         issue
         |> Issue.changeset(attrs, scope)
         |> Changeset.add_error(field, "is invalid")}
    end
  end

  def delete_issue(%Scope{} = scope, %Issue{} = issue) do
    true = Workspaces.project_member?(scope, issue.project_id)

    with {:ok, issue = %Issue{}} <- Repo.delete(issue) do
      broadcast_issue(issue, {:deleted, issue})
      {:ok, issue}
    end
  end

  def change_issue(%Scope{} = scope, %Issue{} = issue, attrs \\ %{}) do
    changeset = Issue.changeset(issue, attrs, scope)
    maybe_add_scope_error(changeset, scope, issue, attrs)
  end

  def update_issue_status(%Scope{} = scope, %Issue{} = issue, status) when is_binary(status) do
    update_issue(scope, issue, %{"status" => status})
  end

  def claim_issue(%Scope{} = scope, %Issue{} = issue) do
    true = Workspaces.project_member?(scope, issue.project_id)

    cond do
      is_nil(issue.claimed_by_id) or issue.claimed_by_id == scope.user.id ->
        update_issue(scope, issue, %{"claimed_by_id" => scope.user.id, "status" => "in_progress"})

      true ->
        {:error, :already_claimed}
    end
  end

  def unclaim_issue(%Scope{} = scope, %Issue{} = issue) do
    true = Workspaces.project_member?(scope, issue.project_id)
    true = issue.claimed_by_id == scope.user.id
    update_issue(scope, issue, %{"claimed_by_id" => nil})
  end

  def organization_options(%Scope{} = scope) do
    Workspaces.list_projects(scope)
    |> Enum.uniq_by(& &1.organization_id)
    |> Enum.map(&{&1.organization.name, &1.organization_id})
    |> Enum.sort_by(fn {label, _id} -> label end)
  end

  def project_options(%Scope{} = scope), do: project_options(scope, "all")

  def project_options(%Scope{} = scope, "all") do
    Workspaces.list_projects(scope) |> Enum.map(&{"#{&1.name} (#{&1.project_key})", &1.id})
  end

  def project_options(%Scope{} = scope, organization_id) when is_binary(organization_id) do
    Workspaces.list_projects(scope)
    |> Enum.filter(&(&1.organization_id == organization_id))
    |> Enum.map(&{"#{&1.name} (#{&1.project_key})", &1.id})
  end

  def project_options(%Scope{} = scope, _organization_id), do: project_options(scope, "all")

  def get_error_trends(%Scope{} = scope, days_count \\ 30) do
    today = Date.utc_today()
    start_date = Date.add(today, -(days_count - 1))
    project_ids = Workspaces.list_projects(scope) |> Enum.map(& &1.id)

    start_dt = DateTime.new!(start_date, ~T[00:00:00], "Etc/UTC")

    issues =
      Issue
      |> where([i], i.project_id in ^project_ids)
      |> where([i], i.inserted_at >= ^start_dt or i.updated_at >= ^start_dt)
      |> Repo.all()

    Enum.map(0..(days_count - 1), fn offset ->
      date = Date.add(start_date, offset)

      new_count =
        Enum.count(issues, fn i ->
          DateTime.to_date(i.inserted_at) == date
        end)

      resolved_count =
        Enum.count(issues, fn i ->
          (i.status == "resolved" and i.updated_at) && DateTime.to_date(i.updated_at) == date
        end)

      {date, %{count: new_count, resolved: resolved_count}}
    end)
  end

  defp maybe_filter_status(query, "all"), do: query
  defp maybe_filter_status(query, status), do: where(query, [i], i.status == ^status)

  defp maybe_filter_organization(query, "all"), do: query

  defp maybe_filter_organization(query, organization_id),
    do: where(query, [i], i.organization_id == ^organization_id)

  defp maybe_filter_project(query, "all"), do: query
  defp maybe_filter_project(query, project_id), do: where(query, [i], i.project_id == ^project_id)

  defp maybe_add_scope_error(changeset, scope, issue, attrs) do
    case validate_issue_scope(scope, attrs, issue) do
      :ok ->
        changeset

      {:error, field} ->
        Changeset.add_error(changeset, field, "is invalid")
    end
  end

  defp validate_issue_scope(scope, attrs, issue \\ %Issue{}) do
    organization_id = attrs["organization_id"] || attrs[:organization_id] || issue.organization_id
    project_id = attrs["project_id"] || attrs[:project_id] || issue.project_id

    cond do
      not is_binary(organization_id) ->
        {:error, :organization_id}

      not is_binary(project_id) ->
        {:error, :project_id}

      not Workspaces.project_member?(scope, project_id) ->
        {:error, :project_id}

      not Repo.exists?(
        from(p in Project, where: p.id == ^project_id and p.organization_id == ^organization_id)
      ) ->
        {:error, :project_id}

      true ->
        :ok
    end
  end
end
