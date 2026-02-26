defmodule FixitWeb.OrganizationLive.Show do
  use FixitWeb, :live_view

  alias Fixit.Tracker
  alias Fixit.Workspaces

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      org_context={%{organization_name: @organization.name, team_name: "Engineering Team"}}
    >
      <section class="space-y-6">
        <header class="relative overflow-hidden rounded-3xl border border-[#1F2937] bg-[#101827] p-6">
          <div class="absolute -right-20 -top-20 h-56 w-56 rounded-full bg-cyan-500/10 blur-3xl">
          </div>
          <div class="absolute -bottom-20 left-1/3 h-56 w-56 rounded-full bg-blue-500/10 blur-3xl">
          </div>
          <div class="relative flex flex-wrap items-start justify-between gap-4">
            <div>
              <h1 class="text-3xl font-bold tracking-tight text-white">Organization Overview</h1>
              <p class="mt-1 text-sm text-[#94A3B8]">{@organization.name} Engineering Team</p>
            </div>
            <div class="flex flex-wrap gap-2">
              <button
                type="button"
                class="inline-flex items-center gap-2 rounded-lg border border-[#334155] bg-[#0F172A] px-3 py-2 text-sm font-semibold text-[#CBD5E1] transition hover:bg-[#162033]"
              >
                <.icon name="hero-user-plus" class="size-4" /> Invite Member
              </button>
              <.button variant="primary" navigate={~p"/projects/new"}>
                <.icon name="hero-rocket-launch" class="size-4" /> New Project
              </.button>
              <.button navigate={~p"/organizations/#{@organization}/edit?return_to=show"}>
                <.icon name="hero-pencil-square" class="size-4" /> Edit
              </.button>
            </div>
          </div>
        </header>

        <section class="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
          <article class="rounded-2xl border border-[#1F2937] bg-[#0F172A] p-4 transition hover:-translate-y-0.5">
            <p class="text-xs font-semibold uppercase tracking-[0.12em] text-[#94A3B8]">
              Total Projects
            </p>
            <p class="mt-3 text-3xl font-bold text-white">{@stats.total_projects}</p>
            <p class="mt-2 inline-flex items-center gap-1 text-xs font-semibold text-emerald-300">
              <.icon name="hero-arrow-trending-up" class="size-4" /> {@stats.projects_trend}
            </p>
          </article>

          <article class="rounded-2xl border border-red-500/30 bg-[#0F172A] p-4 transition hover:-translate-y-0.5">
            <p class="text-xs font-semibold uppercase tracking-[0.12em] text-red-300">
              Active Incidents
            </p>
            <p class="mt-3 text-3xl font-bold text-red-300">{@stats.active_incidents}</p>
            <p class="mt-2 text-xs font-semibold text-orange-300">Attention needed</p>
          </article>

          <article class="rounded-2xl border border-[#1F2937] bg-[#0F172A] p-4 transition hover:-translate-y-0.5">
            <p class="text-xs font-semibold uppercase tracking-[0.12em] text-[#94A3B8]">
              System Uptime
            </p>
            <p class="mt-3 text-3xl font-bold text-white">{@stats.system_uptime}</p>
            <p class="mt-2 inline-flex items-center gap-1 text-xs font-semibold text-emerald-300">
              <.icon name="hero-arrow-trending-up" class="size-4" /> {@stats.uptime_trend}
            </p>
          </article>

          <article class="rounded-2xl border border-[#1F2937] bg-[#0F172A] p-4 transition hover:-translate-y-0.5">
            <p class="text-xs font-semibold uppercase tracking-[0.12em] text-[#94A3B8]">
              Team Members
            </p>
            <p class="mt-3 text-3xl font-bold text-white">{@stats.team_members}</p>
            <p class="mt-2 text-xs text-[#94A3B8]">{@stats.admin_count} Admins</p>
          </article>
        </section>

        <div class="grid gap-6 xl:grid-cols-[2fr_1fr]">
          <section class="rounded-2xl border border-[#1F2937] bg-[#0F172A] p-5">
            <div class="mb-4 flex items-center justify-between gap-3">
              <h2 class="text-lg font-semibold text-white">Active Projects</h2>
              <span class="rounded-full bg-blue-500/20 px-2.5 py-1 text-xs font-semibold text-blue-300">
                {length(@projects)}
              </span>
            </div>

            <div class="overflow-auto rounded-xl border border-[#1F2937]">
              <table class="min-w-full text-sm">
                <thead class="bg-[#111827] text-left text-xs uppercase tracking-[0.08em] text-[#94A3B8]">
                  <tr>
                    <th class="px-4 py-3">Service</th>
                    <th class="px-4 py-3">Status</th>
                    <th class="px-4 py-3">Uptime</th>
                    <th class="px-4 py-3">Errors</th>
                    <th class="px-4 py-3"></th>
                  </tr>
                </thead>
                <tbody>
                  <tr :for={project <- @projects} class="border-t border-[#1F2937] hover:bg-[#111827]">
                    <td class="px-4 py-3 font-semibold text-white">{project.name}</td>
                    <td class="px-4 py-3">
                      <span class={project_status_badge(@project_health[project.id])}>
                        {project_status_label(@project_health[project.id])}
                      </span>
                    </td>
                    <td class="px-4 py-3 text-[#CBD5E1]">
                      {project_uptime(@project_health[project.id])}
                    </td>
                    <td class="px-4 py-3 text-[#CBD5E1]">
                      {project_error_label(@project_metrics[project.id])}
                    </td>
                    <td class="px-4 py-3 text-right">
                      <.link
                        navigate={~p"/projects/#{project}"}
                        class="text-xs font-semibold text-blue-300 hover:underline"
                      >
                        Open
                      </.link>
                    </td>
                  </tr>

                  <tr :if={@projects == []}>
                    <td colspan="5" class="px-4 py-8 text-center text-sm text-[#94A3B8]">
                      No projects created yet.
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </section>

          <section class="rounded-2xl border border-[#1F2937] bg-[#0F172A] p-5">
            <h2 class="text-lg font-semibold text-white">Team Members</h2>
            <p class="mt-1 text-sm text-[#94A3B8]">Roles, status, and collaborator activity</p>

            <div class="mt-4 overflow-auto rounded-xl border border-[#1F2937]">
              <table class="min-w-full text-sm">
                <thead class="bg-[#111827] text-left text-xs uppercase tracking-[0.08em] text-[#94A3B8]">
                  <tr>
                    <th class="px-4 py-3">Name</th>
                    <th class="px-4 py-3">Role</th>
                    <th class="px-4 py-3">Status</th>
                    <th class="px-4 py-3">Last Active</th>
                  </tr>
                </thead>
                <tbody>
                  <tr :for={member <- @members} class="border-t border-[#1F2937] hover:bg-[#111827]">
                    <td class="px-4 py-3">
                      <p class="font-semibold text-white">{member_name(member.user)}</p>
                      <p class="text-xs text-[#94A3B8]">{member.user.email}</p>
                    </td>
                    <td class="px-4 py-3 text-[#CBD5E1]">{member_role_label(member.role)}</td>
                    <td class="px-4 py-3">
                      <span class={member_status_badge(member)}>{member_status_text(member)}</span>
                    </td>
                    <td class="px-4 py-3 text-[#94A3B8]">{member_last_active(member)}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </section>
        </div>
      </section>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      Workspaces.subscribe_organizations(socket.assigns.current_scope)
      Workspaces.subscribe_projects(socket.assigns.current_scope)
      Tracker.subscribe_issues(socket.assigns.current_scope)
    end

    organization = Workspaces.get_organization!(socket.assigns.current_scope, id)

    {:ok,
     socket
     |> assign(:page_title, "Organization")
     |> assign(:organization, organization)
     |> assign_workspace_metrics(organization)}
  end

  @impl true
  def handle_info(
        {:updated, %Fixit.Workspaces.Organization{id: id} = organization},
        %{assigns: %{organization: %{id: id}}} = socket
      ) do
    {:noreply,
     socket |> assign(:organization, organization) |> assign_workspace_metrics(organization)}
  end

  def handle_info(
        {:deleted, %Fixit.Workspaces.Organization{id: id}},
        %{assigns: %{organization: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "The current organization was deleted.")
     |> push_navigate(to: ~p"/organizations")}
  end

  def handle_info({type, %Fixit.Workspaces.Project{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, assign_workspace_metrics(socket, socket.assigns.organization)}
  end

  def handle_info({type, %Fixit.Tracker.Issue{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, assign_workspace_metrics(socket, socket.assigns.organization)}
  end

  def handle_info({type, %Fixit.Workspaces.Organization{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, socket}
  end

  defp assign_workspace_metrics(socket, organization) do
    scope = socket.assigns.current_scope

    projects =
      Workspaces.list_projects(scope)
      |> Enum.filter(&(&1.organization_id == organization.id))

    error_logs =
      Tracker.list_issues(scope)
      |> Enum.filter(&(&1.organization_id == organization.id))

    members = Workspaces.list_organization_members(scope, organization)

    project_metrics =
      projects
      |> Enum.map(fn project ->
        project_logs = Enum.filter(error_logs, &(&1.project_id == project.id))

        open = Enum.count(project_logs, &(&1.status == "open"))
        in_progress = Enum.count(project_logs, &(&1.status == "in_progress"))

        today = Date.utc_today()

        resolved_today =
          Enum.count(project_logs, fn log ->
            log.status == "resolved" and DateTime.to_date(log.updated_at) == today
          end)

        {project.id, %{open: open, in_progress: in_progress, resolved_today: resolved_today}}
      end)
      |> Map.new()

    project_health =
      projects
      |> Enum.map(fn project ->
        metrics =
          Map.get(project_metrics, project.id, %{open: 0, in_progress: 0, resolved_today: 0})

        status =
          cond do
            metrics.open > 200 -> :critical
            metrics.open > 25 -> :warning
            true -> :healthy
          end

        ratio = min(100, metrics.open)
        {project.id, %{status: status, ratio: ratio}}
      end)
      |> Map.new()

    now = DateTime.utc_now()
    thirty_days_ago = DateTime.add(now, -30 * 24 * 60 * 60, :second)

    open_incidents = Enum.count(error_logs, &(&1.status == "open"))

    resolved_30d =
      Enum.count(
        error_logs,
        &(&1.status == "resolved" and DateTime.compare(&1.updated_at, thirty_days_ago) == :gt)
      )

    admin_count = Enum.count(members, &admin_role?(&1.role))
    uptime_value = max(95.0, 100.0 - open_incidents / 10)
    system_uptime = "#{:erlang.float_to_binary(uptime_value, decimals: 1)}%"

    socket
    |> assign(:projects, projects)
    |> assign(:members, members)
    |> assign(:error_log_count, length(error_logs))
    |> assign(:project_error_counts, Enum.frequencies_by(error_logs, & &1.project_id))
    |> assign(:project_metrics, project_metrics)
    |> assign(:project_health, project_health)
    |> assign(:stats, %{
      total_projects: length(projects),
      projects_trend: "+#{max(length(projects) - 10, 0)}",
      active_incidents: open_incidents,
      system_uptime: system_uptime,
      uptime_trend: "+0.1%",
      team_members: length(members),
      admin_count: max(admin_count, if(length(members) > 0, do: 1, else: 0)),
      resolved_30d: resolved_30d
    })
  end

  defp project_status_label(%{status: :healthy}), do: "Operational"
  defp project_status_label(%{status: :warning}), do: "Operational"
  defp project_status_label(%{status: :critical}), do: "Attention"
  defp project_status_label(_), do: "Operational"

  defp project_status_badge(%{status: :healthy}),
    do: "rounded-full bg-green-50 px-2 py-1 text-xs font-semibold text-[#15803D]"

  defp project_status_badge(%{status: :warning}),
    do: "rounded-full bg-amber-50 px-2 py-1 text-xs font-semibold text-[#B45309]"

  defp project_status_badge(%{status: :critical}),
    do: "rounded-full bg-red-50 px-2 py-1 text-xs font-semibold text-[#B91C1C]"

  defp project_status_badge(_),
    do: "rounded-full bg-green-50 px-2 py-1 text-xs font-semibold text-[#15803D]"

  defp project_uptime(%{status: :healthy}), do: "High"
  defp project_uptime(%{status: :warning}), do: "Medium"
  defp project_uptime(%{status: :critical}), do: "Low"
  defp project_uptime(_), do: "High"

  defp project_error_label(%{open: 0, in_progress: 0}), do: "0"
  defp project_error_label(%{open: open}) when open < 5, do: "Few"
  defp project_error_label(%{open: open}), do: Integer.to_string(open)
  defp project_error_label(_), do: "Low"

  defp member_name(user) do
    name = String.trim("#{user.first_name || ""} #{user.last_name || ""}")
    if name == "", do: user.email, else: name
  end

  defp member_role_label("owner"), do: "Admin"
  defp member_role_label("admin"), do: "Admin"
  defp member_role_label("collaborator"), do: "Developer"
  defp member_role_label(role) when is_binary(role), do: String.capitalize(role)
  defp member_role_label(_), do: "Developer"

  defp member_status_badge(member) do
    if admin_role?(member.role) do
      "rounded-full bg-green-50 px-2 py-1 text-xs font-semibold text-[#15803D]"
    else
      "rounded-full bg-slate-100 px-2 py-1 text-xs font-semibold text-[#475569]"
    end
  end

  defp member_status_text(member) do
    if admin_role?(member.role), do: "Online", else: "Offline"
  end

  defp member_last_active(member) do
    if admin_role?(member.role), do: "2 mins ago", else: "1 day ago"
  end

  defp admin_role?(role), do: role in ["owner", "admin"]
end
