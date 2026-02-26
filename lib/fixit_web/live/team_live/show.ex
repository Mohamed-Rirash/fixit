defmodule FixitWeb.TeamLive.Show do
  use FixitWeb, :live_view

  alias Fixit.Workspaces

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Team {@team.id}
        <:subtitle>This is a team record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/teams"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/teams/#{@team}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit team
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Name">{@team.name}</:item>
        <:item title="Role">{@team.role}</:item>
        <:item title="Organization">{@team.organization && @team.organization.name}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      Workspaces.subscribe_teams(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Show Team")
     |> assign(:team, Workspaces.get_team!(socket.assigns.current_scope, id))}
  end

  @impl true
  def handle_info(
        {:updated, %Fixit.Workspaces.Team{id: id} = team},
        %{assigns: %{team: %{id: id}}} = socket
      ) do
    {:noreply, assign(socket, :team, team)}
  end

  def handle_info(
        {:deleted, %Fixit.Workspaces.Team{id: id}},
        %{assigns: %{team: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "The current team was deleted.")
     |> push_navigate(to: ~p"/teams")}
  end

  def handle_info({type, %Fixit.Workspaces.Team{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, socket}
  end
end
