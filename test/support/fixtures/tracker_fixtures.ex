defmodule Fixit.TrackerFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Fixit.Tracker` context.
  """

  @doc """
  Generate a issue.
  """
  def issue_fixture(scope, attrs \\ %{}) do
    organization = Fixit.WorkspacesFixtures.organization_fixture(scope)
    team = Fixit.WorkspacesFixtures.team_fixture(scope, %{organization_id: organization.id})

    project =
      Fixit.WorkspacesFixtures.project_fixture(scope, %{
        organization_id: organization.id,
        team_id: team.id
      })

    attrs =
      Enum.into(attrs, %{
        description: "Submitting checkout form fails with a server error.",
        error_code: 500,
        error_response: ~s({"error":"Internal Server Error"}),
        headers: ~s({"content-type":"application/json"}),
        method: "POST",
        organization_id: organization.id,
        path: "/api/v1/checkout",
        project_id: project.id,
        payload: ~s({"user_id":"1","plan":"pro"}),
        stack_trace: "RuntimeError: boom",
        status: "open"
      })

    {:ok, issue} = Fixit.Tracker.create_issue(scope, attrs)
    issue
  end
end
