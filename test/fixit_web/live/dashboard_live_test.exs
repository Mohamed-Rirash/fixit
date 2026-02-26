defmodule FixitWeb.DashboardLiveTest do
  use FixitWeb.ConnCase

  import Phoenix.LiveViewTest

  setup :register_and_log_in_user

  test "shows setup workflow for authenticated user", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/dashboard")

    assert html =~ "Total Errors"
    assert html =~ "Projects"
  end

  test "GET / redirects authenticated user to dashboard", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert redirected_to(conn) == ~p"/dashboard"
  end
end
