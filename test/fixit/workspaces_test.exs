defmodule Fixit.WorkspacesTest do
  use Fixit.DataCase

  alias Fixit.Workspaces

  describe "projects" do
    alias Fixit.Workspaces.Project

    import Fixit.AccountsFixtures,
      only: [
        unique_user_email: 0,
        user_fixture: 0,
        user_scope_fixture: 0,
        valid_user_attributes: 1
      ]

    import Fixit.WorkspacesFixtures

    @invalid_attrs %{name: nil, description: nil, project_key: nil}

    test "list_projects/1 returns all scoped projects" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      project = project_fixture(scope)
      other_project = project_fixture(other_scope)
      assert Workspaces.list_projects(scope) == [project]
      assert Workspaces.list_projects(other_scope) == [other_project]
    end

    test "get_project!/2 returns the project with given id" do
      scope = user_scope_fixture()
      project = project_fixture(scope)
      other_scope = user_scope_fixture()
      assert Workspaces.get_project!(scope, project.id) == project
      assert_raise Ecto.NoResultsError, fn -> Workspaces.get_project!(other_scope, project.id) end
    end

    test "create_project/2 with valid data creates a project" do
      scope = user_scope_fixture()
      organization = organization_fixture(scope)
      team = team_fixture(scope, %{organization_id: organization.id})

      valid_attrs = %{
        name: "some name",
        description: "some description",
        project_key: "SOME_KEY",
        organization_id: organization.id,
        team_id: team.id
      }

      assert {:ok, %Project{} = project} = Workspaces.create_project(scope, valid_attrs)
      assert project.name == "some name"
      assert project.description == "some description"
      assert project.project_key == "SOME_KEY"
      assert project.user_id == scope.user.id
    end

    test "create_project/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Workspaces.create_project(scope, @invalid_attrs)
    end

    test "update_project/3 with valid data updates the project" do
      scope = user_scope_fixture()
      project = project_fixture(scope)
      organization = organization_fixture(scope)
      team = team_fixture(scope, %{organization_id: organization.id})

      update_attrs = %{
        name: "some updated name",
        description: "some updated description",
        project_key: "UPDATED_KEY",
        organization_id: organization.id,
        team_id: team.id
      }

      assert {:ok, %Project{} = project} = Workspaces.update_project(scope, project, update_attrs)
      assert project.name == "some updated name"
      assert project.description == "some updated description"
      assert project.project_key == "UPDATED_KEY"
    end

    test "update_project/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      project = project_fixture(scope)

      assert_raise MatchError, fn ->
        Workspaces.update_project(other_scope, project, %{})
      end
    end

    test "update_project/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      project = project_fixture(scope)

      assert {:error, %Ecto.Changeset{}} =
               Workspaces.update_project(scope, project, @invalid_attrs)

      assert project == Workspaces.get_project!(scope, project.id)
    end

    test "delete_project/2 deletes the project" do
      scope = user_scope_fixture()
      project = project_fixture(scope)
      assert {:ok, %Project{}} = Workspaces.delete_project(scope, project)
      assert_raise Ecto.NoResultsError, fn -> Workspaces.get_project!(scope, project.id) end
    end

    test "delete_project/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      project = project_fixture(scope)
      assert_raise MatchError, fn -> Workspaces.delete_project(other_scope, project) end
    end

    test "change_project/2 returns a project changeset" do
      scope = user_scope_fixture()
      project = project_fixture(scope)
      assert %Ecto.Changeset{} = Workspaces.change_project(scope, project)
    end

    test "invite_project_member/4 creates membership for existing user" do
      scope = user_scope_fixture()
      invitee = user_fixture()
      project = project_fixture(scope)

      assert {:ok, _membership} =
               Workspaces.invite_project_member(scope, project, invitee.email, "collaborator")

      member_ids =
        Workspaces.list_project_members(scope, project)
        |> Enum.map(& &1.user_id)

      assert invitee.id in member_ids
    end

    test "invite_project_member/4 sends email for unknown user" do
      scope = user_scope_fixture()
      project = project_fixture(scope)
      unknown_email = unique_user_email()

      assert {:ok, :invite_email_sent} =
               Workspaces.invite_project_member(
                 scope,
                 project,
                 unknown_email,
                 "collaborator"
               )
    end

    test "project invite token can be accepted after registration" do
      scope = user_scope_fixture()
      project = project_fixture(scope)
      invitee_email = unique_user_email()

      assert {:ok, :invite_email_sent} =
               Workspaces.invite_project_member(scope, project, invitee_email, "collaborator")

      invite_token = extract_invite_token_from_last_email()

      assert invite = Workspaces.get_project_invite_by_token(invite_token)
      assert invite.email == invitee_email
      assert invite.project_id == project.id

      assert {:ok, user} =
               Fixit.Accounts.register_user(valid_user_attributes(email: invitee_email))

      assert {:ok, [_accepted_invite]} = Workspaces.accept_project_invites_for_user(user)
      assert Workspaces.project_member?(Fixit.Accounts.Scope.for_user(user), project.id)
    end

    test "remove_project_member/3 removes a collaborator membership" do
      scope = user_scope_fixture()
      project = project_fixture(scope)
      invitee = user_fixture()

      assert {:ok, _membership} =
               Workspaces.invite_project_member(scope, project, invitee.email, "collaborator")

      membership =
        Workspaces.list_project_members(scope, project)
        |> Enum.find(&(&1.user_id == invitee.id))

      assert {:ok, _deleted} = Workspaces.remove_project_member(scope, project, membership.id)

      member_ids =
        Workspaces.list_project_members(scope, project)
        |> Enum.map(& &1.user_id)

      refute invitee.id in member_ids
    end

    test "remove_project_member/3 does not allow removing self" do
      scope = user_scope_fixture()
      project = project_fixture(scope)

      owner_membership =
        Workspaces.list_project_members(scope, project)
        |> Enum.find(&(&1.user_id == scope.user.id))

      assert {:error, :cannot_remove_self} =
               Workspaces.remove_project_member(scope, project, owner_membership.id)
    end
  end

  describe "organizations" do
    alias Fixit.Workspaces.Organization

    import Fixit.AccountsFixtures, only: [user_scope_fixture: 0]
    import Fixit.WorkspacesFixtures

    @invalid_attrs %{name: nil, slug: nil}

    test "list_organizations/1 returns all scoped organizations" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      organization = organization_fixture(scope)
      other_organization = organization_fixture(other_scope)
      assert Workspaces.list_organizations(scope) == [organization]
      assert Workspaces.list_organizations(other_scope) == [other_organization]
    end

    test "get_organization!/2 returns the organization with given id" do
      scope = user_scope_fixture()
      organization = organization_fixture(scope)
      other_scope = user_scope_fixture()
      assert Workspaces.get_organization!(scope, organization.id) == organization

      assert_raise Ecto.NoResultsError, fn ->
        Workspaces.get_organization!(other_scope, organization.id)
      end
    end

    test "create_organization/2 with valid data creates a organization" do
      valid_attrs = %{name: "some name", slug: "some-slug"}
      scope = user_scope_fixture()

      assert {:ok, %Organization{} = organization} =
               Workspaces.create_organization(scope, valid_attrs)

      assert organization.name == "some name"
      assert organization.slug == "some-slug"
      assert organization.user_id == scope.user.id
    end

    test "create_organization/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Workspaces.create_organization(scope, @invalid_attrs)
    end

    test "update_organization/3 with valid data updates the organization" do
      scope = user_scope_fixture()
      organization = organization_fixture(scope)
      update_attrs = %{name: "some updated name", slug: "some-updated-slug"}

      assert {:ok, %Organization{} = organization} =
               Workspaces.update_organization(scope, organization, update_attrs)

      assert organization.name == "some updated name"
      assert organization.slug == "some-updated-slug"
    end

    test "update_organization/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      organization = organization_fixture(scope)

      assert_raise MatchError, fn ->
        Workspaces.update_organization(other_scope, organization, %{})
      end
    end

    test "update_organization/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      organization = organization_fixture(scope)

      assert {:error, %Ecto.Changeset{}} =
               Workspaces.update_organization(scope, organization, @invalid_attrs)

      assert organization == Workspaces.get_organization!(scope, organization.id)
    end

    test "delete_organization/2 deletes the organization" do
      scope = user_scope_fixture()
      organization = organization_fixture(scope)
      assert {:ok, %Organization{}} = Workspaces.delete_organization(scope, organization)

      assert_raise Ecto.NoResultsError, fn ->
        Workspaces.get_organization!(scope, organization.id)
      end
    end

    test "delete_organization/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      organization = organization_fixture(scope)
      assert_raise MatchError, fn -> Workspaces.delete_organization(other_scope, organization) end
    end

    test "change_organization/2 returns a organization changeset" do
      scope = user_scope_fixture()
      organization = organization_fixture(scope)
      assert %Ecto.Changeset{} = Workspaces.change_organization(scope, organization)
    end
  end

  describe "teams" do
    alias Fixit.Workspaces.Team

    import Fixit.AccountsFixtures, only: [user_scope_fixture: 0]
    import Fixit.WorkspacesFixtures

    @invalid_attrs %{name: nil, role: nil, organization_id: nil}

    test "list_teams/1 returns all scoped teams" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      team = team_fixture(scope)
      other_team = team_fixture(other_scope)
      scope_team_ids = Workspaces.list_teams(scope) |> Enum.map(& &1.id)
      other_scope_team_ids = Workspaces.list_teams(other_scope) |> Enum.map(& &1.id)

      assert team.id in scope_team_ids
      assert other_team.id in other_scope_team_ids
    end

    test "get_team!/2 returns the team with given id" do
      scope = user_scope_fixture()
      team = team_fixture(scope)
      other_scope = user_scope_fixture()
      assert Workspaces.get_team!(scope, team.id) == team
      assert_raise Ecto.NoResultsError, fn -> Workspaces.get_team!(other_scope, team.id) end
    end

    test "create_team/2 with valid data creates a team" do
      scope = user_scope_fixture()
      organization = organization_fixture(scope)
      valid_attrs = %{name: "some name", role: "backend", organization_id: organization.id}

      assert {:ok, %Team{} = team} = Workspaces.create_team(scope, valid_attrs)
      assert team.name == "some name"
      assert team.role == "backend"
      assert team.user_id == scope.user.id
    end

    test "create_team/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Workspaces.create_team(scope, @invalid_attrs)
    end

    test "update_team/3 with valid data updates the team" do
      scope = user_scope_fixture()
      team = team_fixture(scope)
      organization = organization_fixture(scope)

      update_attrs = %{
        name: "some updated name",
        role: "frontend",
        organization_id: organization.id
      }

      assert {:ok, %Team{} = team} = Workspaces.update_team(scope, team, update_attrs)
      assert team.name == "some updated name"
      assert team.role == "frontend"
    end

    test "update_team/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      team = team_fixture(scope)

      assert_raise MatchError, fn ->
        Workspaces.update_team(other_scope, team, %{})
      end
    end

    test "update_team/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      team = team_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Workspaces.update_team(scope, team, @invalid_attrs)
      assert team == Workspaces.get_team!(scope, team.id)
    end

    test "delete_team/2 deletes the team" do
      scope = user_scope_fixture()
      team = team_fixture(scope)
      assert {:ok, %Team{}} = Workspaces.delete_team(scope, team)
      assert_raise Ecto.NoResultsError, fn -> Workspaces.get_team!(scope, team.id) end
    end

    test "delete_team/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      team = team_fixture(scope)
      assert_raise MatchError, fn -> Workspaces.delete_team(other_scope, team) end
    end

    test "change_team/2 returns a team changeset" do
      scope = user_scope_fixture()
      team = team_fixture(scope)
      assert %Ecto.Changeset{} = Workspaces.change_team(scope, team)
    end
  end

  defp extract_invite_token_from_last_email do
    messages = Process.info(self(), :messages) |> elem(1)

    email =
      messages
      |> Enum.map(&email_from_message/1)
      |> Enum.reject(&is_nil/1)
      |> Enum.find(fn email ->
        String.contains?(email.text_body || "", "/users/register?invite=")
      end)

    assert email, "Expected invitation email to be delivered"

    body = email.text_body || email.html_body || ""

    case Regex.run(~r/invite=([A-Za-z0-9\-_]+)/, body) do
      [_, token] ->
        token

      _ ->
        flunk("Could not extract invite token from email body: #{inspect(body)}")
    end
  end

  defp email_from_message({:email, %Swoosh.Email{} = email}), do: email
  defp email_from_message({:email, %Swoosh.Email{} = email, _meta}), do: email
  defp email_from_message({:swoosh, :deliver, %Swoosh.Email{} = email}), do: email
  defp email_from_message(_), do: nil
end
