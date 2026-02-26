defmodule Fixit.WorkspacesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Fixit.Workspaces` context.
  """

  @doc """
  Generate a project.
  """
  def project_fixture(scope, attrs \\ %{}) do
    organization = organization_fixture(scope)
    team = team_fixture(scope, %{organization_id: organization.id})

    attrs =
      Enum.into(attrs, %{
        description: "some description",
        name: "some name",
        organization_id: organization.id,
        project_key: "KEY#{System.unique_integer([:positive])}",
        team_id: team.id
      })

    {:ok, project} = Fixit.Workspaces.create_project(scope, attrs)
    project
  end

  @doc """
  Generate a organization.
  """
  def organization_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        name: "some name",
        slug: "org-#{System.unique_integer([:positive])}"
      })

    {:ok, organization} = Fixit.Workspaces.create_organization(scope, attrs)
    organization
  end

  @doc """
  Generate a team.
  """
  def team_fixture(scope, attrs \\ %{}) do
    organization_id =
      case attrs[:organization_id] || attrs["organization_id"] do
        nil -> organization_fixture(scope).id
        value -> value
      end

    attrs =
      Enum.into(attrs, %{
        name: "some name",
        organization_id: organization_id,
        role: "backend"
      })

    {:ok, team} = Fixit.Workspaces.create_team(scope, attrs)
    team
  end
end
