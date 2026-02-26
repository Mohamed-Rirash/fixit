defmodule FixitWeb.IssueLiveTest do
  use FixitWeb.ConnCase

  import Phoenix.LiveViewTest
  import Fixit.TrackerFixtures

  @create_attrs %{
    status: "open",
    path: "/api/v1/tickets",
    description: "Frontend save button fails due to API timeout.",
    payload: ~s({"title":"Broken ticket"}),
    method: "POST",
    error_code: 504,
    error_response: ~s({"error":"gateway timeout"}),
    headers: ~s({"content-type":"application/json"}),
    organization_id: nil,
    stack_trace: "RuntimeError: nope"
  }

  @update_attrs %{
    status: "resolved",
    path: "/api/v1/tickets/1",
    description: "Fixed with backend query optimization.",
    payload: ~s({"id":"1"}),
    method: "GET",
    error_code: 404,
    error_response: ~s({"error":"not found"}),
    headers: ~s({"x-trace":"123"}),
    organization_id: nil,
    stack_trace: "ArgumentError: bad"
  }

  @invalid_attrs %{
    status: "open",
    path: nil,
    description: nil,
    payload: nil,
    method: "GET",
    error_code: nil,
    error_response: nil,
    organization_id: nil,
    project_id: nil
  }

  setup :register_and_log_in_user

  defp create_issue(%{scope: scope}) do
    issue = issue_fixture(scope)

    %{issue: issue}
  end

  defp workspace_refs(%{issue: issue}) do
    %{
      create_attrs:
        @create_attrs
        |> Map.put(:organization_id, issue.organization_id)
        |> Map.put(:project_id, issue.project_id),
      update_attrs:
        @update_attrs
        |> Map.put(:organization_id, issue.organization_id)
        |> Map.put(:project_id, issue.project_id),
      invalid_attrs: Map.put(@invalid_attrs, :project_id, issue.project_id)
    }
  end

  describe "Index" do
    setup [:create_issue, :workspace_refs]

    test "lists all issues", %{conn: conn, issue: issue} do
      {:ok, _index_live, html} = live(conn, ~p"/issues")

      assert html =~ "Error Tracking"
      assert html =~ issue.path
    end

    test "saves new issue", %{
      conn: conn,
      create_attrs: create_attrs,
      invalid_attrs: invalid_attrs
    } do
      {:ok, index_live, _html} = live(conn, ~p"/issues")

      assert {:ok, form_live, _} =
               index_live
               |> element("#new-issue")
               |> render_click()
               |> follow_redirect(conn, ~p"/issues/new")

      assert render(form_live) =~ "Log New API Error"

      assert form_live
             |> form("#issue-form", issue: invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#issue-form", issue: create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/issues")

      html = render(index_live)
      assert html =~ "Error log created successfully"
      assert html =~ "/api/v1/tickets"
    end

    test "updates issue in listing", %{
      conn: conn,
      issue: issue,
      update_attrs: update_attrs,
      invalid_attrs: invalid_attrs
    } do
      {:ok, index_live, _html} = live(conn, ~p"/issues")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#issues-#{issue.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/issues/#{issue}/edit")

      assert render(form_live) =~ "Edit Error Ticket"

      assert form_live
             |> form("#issue-form", issue: invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#issue-form", issue: update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/issues")

      html = render(index_live)
      assert html =~ "Error log updated successfully"
      assert html =~ "/api/v1/tickets/1"
    end

    test "deletes issue in listing", %{conn: conn, issue: issue} do
      {:ok, index_live, _html} = live(conn, ~p"/issues")

      assert index_live |> element("#issues-#{issue.id} button", "Delete") |> render_click()
      refute has_element?(index_live, "#issues-#{issue.id}")
    end
  end

  describe "Show" do
    setup [:create_issue, :workspace_refs]

    test "displays issue", %{conn: conn, issue: issue} do
      {:ok, _show_live, html} = live(conn, ~p"/issues/#{issue}")

      assert html =~ "Error Log"
      assert html =~ issue.path
    end

    test "updates issue and returns to show", %{
      conn: conn,
      issue: issue,
      update_attrs: update_attrs,
      invalid_attrs: invalid_attrs
    } do
      {:ok, form_live, _html} = live(conn, ~p"/issues/#{issue}/edit?return_to=show")

      assert render(form_live) =~ "Edit Error Ticket"

      assert form_live
             |> form("#issue-form", issue: invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#issue-form", issue: update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/issues/#{issue}")

      html = render(show_live)
      assert html =~ "Error log updated successfully"
      assert html =~ "/api/v1/tickets/1"
    end
  end
end
