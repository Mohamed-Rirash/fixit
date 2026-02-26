defmodule Fixit.TrackerTest do
  use Fixit.DataCase

  alias Fixit.Tracker

  describe "issues" do
    alias Fixit.Tracker.Issue

    import Fixit.AccountsFixtures, only: [user_scope_fixture: 0]
    import Fixit.TrackerFixtures
    import Fixit.WorkspacesFixtures

    @invalid_attrs %{
      status: nil,
      path: nil,
      description: nil,
      payload: nil,
      method: nil,
      error_code: nil,
      error_response: nil
    }

    test "list_issues/1 returns all scoped issues" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      issue = issue_fixture(scope)
      other_issue = issue_fixture(other_scope)
      assert Tracker.list_issues(scope) == [issue]
      assert Tracker.list_issues(other_scope) == [other_issue]
    end

    test "get_issue!/2 returns the issue with given id" do
      scope = user_scope_fixture()
      issue = issue_fixture(scope)
      other_scope = user_scope_fixture()
      assert Tracker.get_issue!(scope, issue.id).id == issue.id
      assert_raise Ecto.NoResultsError, fn -> Tracker.get_issue!(other_scope, issue.id) end
    end

    test "create_issue/2 with valid data creates a issue" do
      scope = user_scope_fixture()
      organization = organization_fixture(scope)
      team = team_fixture(scope, %{organization_id: organization.id})

      project =
        project_fixture(scope, %{organization_id: organization.id, team_id: team.id})

      valid_attrs = %{
        status: "open",
        path: "/api/v1/users",
        description: "List users API failed from frontend users table page.",
        payload: ~s({"page":1}),
        method: "GET",
        error_code: 500,
        error_response: ~s({"error":"oops"}),
        organization_id: organization.id,
        project_id: project.id
      }

      assert {:ok, %Issue{} = issue} = Tracker.create_issue(scope, valid_attrs)
      assert issue.status == "open"
      assert issue.path == "/api/v1/users"
      assert issue.description == "List users API failed from frontend users table page."
      assert issue.payload == ~s({"page":1})
      assert issue.method == "GET"
      assert issue.error_code == 500
      assert issue.error_response == ~s({"error":"oops"})
      assert issue.user_id == scope.user.id
    end

    test "create_issue/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Tracker.create_issue(scope, @invalid_attrs)
    end

    test "update_issue/3 with valid data updates the issue" do
      scope = user_scope_fixture()
      issue = issue_fixture(scope)

      update_attrs = %{
        status: "resolved",
        path: "/api/v1/users/1",
        description: "Issue fixed and endpoint now works.",
        payload: ~s({"id":"1"}),
        method: "GET",
        error_code: 404,
        error_response: ~s({"error":"not found"})
      }

      assert {:ok, %Issue{} = issue} = Tracker.update_issue(scope, issue, update_attrs)
      assert issue.status == "resolved"
      assert issue.path == "/api/v1/users/1"
      assert issue.description == "Issue fixed and endpoint now works."
      assert issue.payload == ~s({"id":"1"})
      assert issue.method == "GET"
      assert issue.error_code == 404
      assert issue.error_response == ~s({"error":"not found"})
    end

    test "update_issue/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      issue = issue_fixture(scope)

      assert_raise MatchError, fn ->
        Tracker.update_issue(other_scope, issue, %{})
      end
    end

    test "update_issue/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      issue = issue_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Tracker.update_issue(scope, issue, @invalid_attrs)
      assert Tracker.get_issue!(scope, issue.id).id == issue.id
    end

    test "delete_issue/2 deletes the issue" do
      scope = user_scope_fixture()
      issue = issue_fixture(scope)
      assert {:ok, %Issue{}} = Tracker.delete_issue(scope, issue)
      assert_raise Ecto.NoResultsError, fn -> Tracker.get_issue!(scope, issue.id) end
    end

    test "delete_issue/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      issue = issue_fixture(scope)
      assert_raise MatchError, fn -> Tracker.delete_issue(other_scope, issue) end
    end

    test "change_issue/2 returns a issue changeset" do
      scope = user_scope_fixture()
      issue = issue_fixture(scope)
      assert %Ecto.Changeset{} = Tracker.change_issue(scope, issue)
    end
  end
end
