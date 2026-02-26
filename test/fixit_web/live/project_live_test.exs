defmodule FixitWeb.ProjectLiveTest do
  use FixitWeb.ConnCase

  alias Fixit.Workspaces

  import Phoenix.LiveViewTest
  import Fixit.AccountsFixtures
  import Fixit.WorkspacesFixtures

  @invalid_attrs %{
    name: nil,
    description: nil,
    project_key: nil,
    organization_id: nil
  }

  setup :register_and_log_in_user

  defp create_project(%{scope: scope}) do
    project = project_fixture(scope)

    %{project: project}
  end

  defp workspace_refs(%{project: project}) do
    %{
      create_attrs: %{
        name: "some name",
        description: "some description",
        project_key: "SOME_KEY",
        organization_id: project.organization_id,
        team_id: project.team_id
      },
      update_attrs: %{
        name: "some updated name",
        description: "some updated description",
        project_key: "UPDATED_KEY",
        organization_id: project.organization_id,
        team_id: project.team_id
      }
    }
  end

  describe "Index" do
    setup [:create_project, :workspace_refs]

    test "lists all projects", %{conn: conn, project: project} do
      {:ok, _index_live, html} = live(conn, ~p"/projects")

      assert html =~ "Projects"
      assert html =~ project.name
    end

    test "saves new project", %{conn: conn, create_attrs: create_attrs} do
      {:ok, index_live, _html} = live(conn, ~p"/projects")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Project")
               |> render_click()
               |> follow_redirect(conn, ~p"/projects/new")

      assert render(form_live) =~ "New Project"

      assert form_live
             |> form("#project-form", project: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#project-form", project: create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/projects")

      html = render(index_live)
      assert html =~ "Project created successfully"
      assert html =~ "some name"
    end

    test "updates project in listing", %{conn: conn, project: project, update_attrs: update_attrs} do
      {:ok, index_live, _html} = live(conn, ~p"/projects")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#projects-#{project.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/projects/#{project}/edit")

      assert render(form_live) =~ "Edit Project"

      assert form_live
             |> form("#project-form", project: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#project-form", project: update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/projects")

      html = render(index_live)
      assert html =~ "Project updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes project in listing", %{conn: conn, project: project} do
      {:ok, index_live, _html} = live(conn, ~p"/projects")

      assert index_live |> element("#projects-#{project.id} button", "Delete") |> render_click()
      refute has_element?(index_live, "#projects-#{project.id}")
    end
  end

  describe "Show" do
    setup [:create_project, :workspace_refs]

    test "displays project", %{conn: conn, project: project} do
      {:ok, _show_live, html} = live(conn, ~p"/projects/#{project}")

      assert html =~ "Project Team"
      assert html =~ project.name
    end

    test "updates project and returns to show", %{
      conn: conn,
      project: project,
      update_attrs: update_attrs
    } do
      {:ok, show_live, _html} = live(conn, ~p"/projects/#{project}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/projects/#{project}/edit?return_to=show")

      assert render(form_live) =~ "Edit Project"

      assert form_live
             |> form("#project-form", project: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#project-form", project: update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/projects/#{project}")

      html = render(show_live)
      assert html =~ "Project updated successfully"
      assert html =~ "some updated name"
    end

    test "admin can remove collaborator", %{conn: conn, scope: scope, project: project} do
      collaborator = user_fixture()

      assert {:ok, _membership} =
               Workspaces.invite_project_member(
                 scope,
                 project,
                 collaborator.email,
                 "collaborator"
               )

      membership =
        Workspaces.list_project_members(scope, project)
        |> Enum.find(&(&1.user_id == collaborator.id))

      {:ok, show_live, _html} = live(conn, ~p"/projects/#{project}")

      assert has_element?(show_live, "#remove-member-#{membership.id}")

      show_live
      |> element("#remove-member-#{membership.id}")
      |> render_click()

      assert render(show_live) =~ "Collaborator removed."
      refute has_element?(show_live, "#remove-member-#{membership.id}")
    end
  end
end
