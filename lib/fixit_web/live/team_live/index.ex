defmodule FixitWeb.TeamLive.Index do
  use FixitWeb, :live_view

  alias Fixit.Workspaces

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Listing Teams
        <:actions>
          <.button variant="primary" navigate={~p"/teams/new"}>
            <.icon name="hero-plus" /> New Team
          </.button>
        </:actions>
      </.header>

      <.table
        id="teams"
        rows={@streams.teams}
        row_click={fn {_id, team} -> JS.navigate(~p"/teams/#{team}") end}
      >
        <:col :let={{_id, team}} label="Name">{team.name}</:col>
        <:col :let={{_id, team}} label="Role">{team.role}</:col>
        <:col :let={{_id, team}} label="Organization">
          {team.organization && team.organization.name}
        </:col>
        <:action :let={{_id, team}}>
          <div class="sr-only">
            <.link navigate={~p"/teams/#{team}"}>Show</.link>
          </div>
          <.link navigate={~p"/teams/#{team}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, team}}>
          <.link
            phx-click={JS.push("delete", value: %{id: team.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Workspaces.subscribe_teams(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Listing Teams")
     |> stream(:teams, list_teams(socket.assigns.current_scope))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    team = Workspaces.get_team!(socket.assigns.current_scope, id)
    {:ok, _} = Workspaces.delete_team(socket.assigns.current_scope, team)

    {:noreply, stream_delete(socket, :teams, team)}
  end

  @impl true
  def handle_info({type, %Fixit.Workspaces.Team{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, stream(socket, :teams, list_teams(socket.assigns.current_scope), reset: true)}
  end

  defp list_teams(current_scope) do
    Workspaces.list_teams(current_scope)
  end
end
