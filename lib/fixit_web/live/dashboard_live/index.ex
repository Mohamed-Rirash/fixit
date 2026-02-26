defmodule FixitWeb.DashboardLive.Index do
  use FixitWeb, :live_view

  alias Fixit.Tracker
  alias Fixit.Workspaces

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section class="space-y-6">
        <div class="grid gap-4 lg:grid-cols-4">
          <article class="rounded-xl border border-[#1F2937] bg-[#141C2B] p-4 transition hover:-translate-y-0.5">
            <div class="flex items-center justify-between gap-3">
              <p class="text-xs uppercase tracking-[0.12em] text-[#9CA3AF]">Total Errors</p>
              <.icon name="hero-bug-ant" class="size-4 text-[#EF4444]" />
            </div>
            <p class="mt-3 text-3xl font-black text-[#F3F4F6]">{@counts.error_logs}</p>
            <p class="mt-2 text-xs text-[#9CA3AF]">Last 30 days</p>
          </article>
          <article class="rounded-xl border border-[#1F2937] bg-[#141C2B] p-4 transition hover:-translate-y-0.5">
            <div class="flex items-center justify-between gap-3">
              <p class="text-xs uppercase tracking-[0.12em] text-[#9CA3AF]">Open Issues</p>
              <.icon name="hero-exclamation-triangle" class="size-4 text-[#F59E0B]" />
            </div>
            <p class="mt-3 text-3xl font-black text-[#F3F4F6]">{@stats.open_issues}</p>
            <p class="mt-2 text-xs text-[#9CA3AF]">Need attention</p>
          </article>
          <article class="rounded-xl border border-[#1F2937] bg-[#141C2B] p-4 transition hover:-translate-y-0.5">
            <div class="flex items-center justify-between gap-3">
              <p class="text-xs uppercase tracking-[0.12em] text-[#9CA3AF]">Resolved</p>
              <.icon name="hero-check-circle" class="size-4 text-[#22C55E]" />
            </div>
            <p class="mt-3 text-3xl font-black text-[#F3F4F6]">{@stats.resolved_issues}</p>
            <p class="mt-2 text-xs text-[#9CA3AF]">This month</p>
          </article>
          <article class="rounded-xl border border-[#1F2937] bg-[#141C2B] p-4 transition hover:-translate-y-0.5">
            <div class="flex items-center justify-between gap-3">
              <p class="text-xs uppercase tracking-[0.12em] text-[#9CA3AF]">Avg Resolution</p>
              <.icon name="hero-clock" class="size-4 text-[#3B82F6]" />
            </div>
            <p class="mt-3 text-3xl font-black text-[#F3F4F6]">{@stats.avg_resolution}h</p>
            <p class="mt-2 text-xs text-[#9CA3AF]">Response time</p>
          </article>
        </div>

        <div class="grid gap-6 lg:grid-cols-2">
          <!-- Error Trends Chart -->
          <div class="rounded-xl border border-[#1F2937] bg-[#111827] p-6">
            <div class="flex items-center justify-between gap-3">
              <h2 class="text-base font-semibold text-[#F3F4F6]">Error Trends</h2>
              <div class="flex items-center gap-2">
                <button class="text-xs font-semibold text-[#9CA3AF] hover:text-[#F3F4F6]">7d</button>
                <button class="rounded-lg bg-[#1E3A8A] px-2 py-1 text-xs font-semibold text-[#BFDBFE]">
                  30d
                </button>
                <button class="text-xs font-semibold text-[#9CA3AF] hover:text-[#F3F4F6]">90d</button>
              </div>
            </div>
            <div class="mt-4 h-64">
              <svg class="h-full w-full" viewBox="0 0 400 200">
                <!-- Grid lines -->
                <g class="stroke-[#374151] stroke-opacity-30">
                  <line x1="40" y1="20" x2="40" y2="160" />
                  <line x1="40" y1="160" x2="380" y2="160" />
                  <line x1="40" y1="40" x2="380" y2="40" stroke-dasharray="2,2" />
                  <line x1="40" y1="80" x2="380" y2="80" stroke-dasharray="2,2" />
                  <line x1="40" y1="120" x2="380" y2="120" stroke-dasharray="2,2" />
                </g>
                
    <!-- Chart data -->
                <polyline
                  fill="none"
                  stroke="#EF4444"
                  stroke-width="2"
                  points={chart_points(@error_trends, :count)}
                />
                <polyline
                  fill="none"
                  stroke="#22C55E"
                  stroke-width="2"
                  points={chart_points(@error_trends, :resolved)}
                />
                
    <!-- Data points -->
                <g :for={{{_date, data}, index} <- Enum.with_index(@error_trends)}>
                  <circle cx={x_position(index)} cy={y_position(data.count)} r="3" fill="#EF4444" />
                  <circle cx={x_position(index)} cy={y_position(data.resolved)} r="3" fill="#22C55E" />
                </g>
                
    <!-- Y-axis labels -->
                <text x="30" y="25" class="fill-[#9CA3AF] text-xs" text-anchor="end">50</text>
                <text x="30" y="65" class="fill-[#9CA3AF] text-xs" text-anchor="end">40</text>
                <text x="30" y="105" class="fill-[#9CA3AF] text-xs" text-anchor="end">30</text>
                <text x="30" y="145" class="fill-[#9CA3AF] text-xs" text-anchor="end">20</text>
                <text x="30" y="165" class="fill-[#9CA3AF] text-xs" text-anchor="end">0</text>
              </svg>
            </div>
            <div class="mt-4 flex items-center justify-center gap-6">
              <div class="flex items-center gap-2">
                <div class="size-3 rounded-full bg-[#EF4444]"></div>
                <span class="text-xs text-[#9CA3AF]">New Errors</span>
              </div>
              <div class="flex items-center gap-2">
                <div class="size-3 rounded-full bg-[#22C55E]"></div>
                <span class="text-xs text-[#9CA3AF]">Resolved</span>
              </div>
            </div>
          </div>
          
    <!-- Status Distribution -->
          <div class="rounded-xl border border-[#1F2937] bg-[#111827] p-6">
            <h2 class="text-base font-semibold text-[#F3F4F6]">Status Distribution</h2>
            <div class="mt-4 flex h-64 items-center justify-center">
              <div class="relative h-48 w-48">
                <svg class="h-full w-full transform -rotate-90" viewBox="0 0 200 200">
                  <!-- Background circle -->
                  <circle
                    cx="100"
                    cy="100"
                    r="80"
                    fill="none"
                    stroke="#374151"
                    stroke-width="20"
                  />
                  
    <!-- Open segment -->
                  <circle
                    cx="100"
                    cy="100"
                    r="80"
                    fill="none"
                    stroke="#EF4444"
                    stroke-width="20"
                    stroke-dasharray={pie_segment(@status_distribution, :open)}
                    stroke-dashoffset="0"
                  />
                  
    <!-- In Progress segment -->
                  <circle
                    cx="100"
                    cy="100"
                    r="80"
                    fill="none"
                    stroke="#F59E0B"
                    stroke-width="20"
                    stroke-dasharray={pie_segment(@status_distribution, :in_progress)}
                    stroke-dashoffset={pie_offset(@status_distribution, [:open])}
                  />
                  
    <!-- Resolved segment -->
                  <circle
                    cx="100"
                    cy="100"
                    r="80"
                    fill="none"
                    stroke="#22C55E"
                    stroke-width="20"
                    stroke-dasharray={pie_segment(@status_distribution, :resolved)}
                    stroke-dashoffset={pie_offset(@status_distribution, [:open, :in_progress])}
                  />
                </svg>
                
    <!-- Center text -->
                <div class="absolute inset-0 flex items-center justify-center">
                  <div class="text-center">
                    <p class="text-2xl font-black text-[#F3F4F6]">{@counts.error_logs}</p>
                    <p class="text-xs text-[#9CA3AF]">Total Issues</p>
                  </div>
                </div>
              </div>
            </div>
            <div class="mt-4 grid grid-cols-3 gap-4">
              <div class="text-center">
                <div class="flex items-center justify-center gap-2">
                  <div class="size-3 rounded-full bg-[#EF4444]"></div>
                  <span class="text-xs text-[#9CA3AF]">Open</span>
                </div>
                <p class="mt-1 text-lg font-semibold text-[#F3F4F6]">{@status_distribution.open}</p>
              </div>
              <div class="text-center">
                <div class="flex items-center justify-center gap-2">
                  <div class="size-3 rounded-full bg-[#F59E0B]"></div>
                  <span class="text-xs text-[#9CA3AF]">In Progress</span>
                </div>
                <p class="mt-1 text-lg font-semibold text-[#F3F4F6]">
                  {@status_distribution.in_progress}
                </p>
              </div>
              <div class="text-center">
                <div class="flex items-center justify-center gap-2">
                  <div class="size-3 rounded-full bg-[#22C55E]"></div>
                  <span class="text-xs text-[#9CA3AF]">Resolved</span>
                </div>
                <p class="mt-1 text-lg font-semibold text-[#F3F4F6]">
                  {@status_distribution.resolved}
                </p>
              </div>
            </div>
          </div>
        </div>
        
    <!-- Error Methods and Projects -->
        <div class="grid gap-6 lg:grid-cols-2">
          <!-- HTTP Methods Distribution -->
          <div class="rounded-xl border border-[#1F2937] bg-[#111827] p-6">
            <h2 class="text-base font-semibold text-[#F3F4F6]">HTTP Methods</h2>
            <div class="mt-4 space-y-3">
              <div :for={{method, count} <- @method_distribution} class="space-y-2">
                <div class="flex items-center justify-between text-sm">
                  <span class="font-medium text-[#F3F4F6]">{method}</span>
                  <span class="text-[#9CA3AF]">{count}</span>
                </div>
                <div class="h-2 rounded-full bg-[#374151]">
                  <div
                    class="h-2 rounded-full bg-gradient-to-r from-[#3B82F6] to-[#60A5FA]"
                    style={"width: #{method_percentage(count, @counts.error_logs)}%"}
                  >
                  </div>
                </div>
              </div>
            </div>
          </div>
          
    <!-- Top Projects -->
          <div class="rounded-xl border border-[#1F2937] bg-[#111827] p-6">
            <h2 class="text-base font-semibold text-[#F3F4F6]">Top Projects</h2>
            <div class="mt-4 space-y-3">
              <div
                :for={{project, count} <- @top_projects}
                class="flex items-center justify-between rounded-lg border border-[#374151] bg-[#141C2B] px-3 py-2"
              >
                <div>
                  <p class="font-medium text-[#F3F4F6]">{project.name}</p>
                  <p class="text-xs text-[#9CA3AF]">{count} errors</p>
                </div>
                <div class="text-right">
                  <p class="text-sm font-semibold text-[#F3F4F6]">
                    {error_rate(count, project.total_requests)}%
                  </p>
                  <p class="text-xs text-[#9CA3AF]">error rate</p>
                </div>
              </div>
            </div>
          </div>
        </div>
        
    <!-- Recent Error Logs -->
        <div class="rounded-xl border border-[#1F2937] bg-[#111827] p-5">
          <div class="flex items-center justify-between gap-3">
            <h2 class="text-base font-semibold text-[#F3F4F6]">Recent Error Logs</h2>
            <.link navigate={~p"/issues"} class="text-sm font-semibold text-[#3B82F6]">
              View all
            </.link>
          </div>
          <div class="mt-3 space-y-2">
            <p
              :if={@recent_error_logs == []}
              class="rounded-lg bg-[#141C2B] px-3 py-2 text-sm text-[#9CA3AF]"
            >
              No error logs yet.
            </p>
            <.link
              :for={issue <- @recent_error_logs}
              navigate={~p"/issues/#{issue}"}
              class="flex items-center justify-between gap-3 rounded-lg border border-[#1F2937] bg-[#141C2B] px-3 py-2 text-sm transition hover:border-blue-400/50"
            >
              <div class="flex items-center gap-3">
                <span class={"rounded-md px-2 py-1 text-xs font-bold #{method_color(issue.method)}"}>
                  {issue.method}
                </span>
                <span class="truncate font-mono text-[#F3F4F6]">{issue.path}</span>
              </div>
              <div class="flex items-center gap-2">
                <span class={"rounded-md px-2 py-1 text-xs font-bold uppercase #{status_color(issue.status)}"}>
                  {issue.status}
                </span>
                <span class="text-xs text-[#9CA3AF]">{format_timestamp(issue.inserted_at)}</span>
              </div>
            </.link>
          </div>
        </div>
      </section>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Tracker.subscribe_issues(socket.assigns.current_scope)
    end

    scope = socket.assigns.current_scope

    {:ok,
     socket
     |> assign(:page_title, "Dashboard")
     |> assign_dashboard(scope)}
  end

  @impl true
  def handle_info({event, _issue}, socket) when event in [:created, :updated, :deleted] do
    {:noreply, assign_dashboard(socket, socket.assigns.current_scope)}
  end

  defp assign_dashboard(socket, scope) do
    organizations = Workspaces.list_organizations(scope)
    projects = Workspaces.list_projects(scope)
    error_logs = Tracker.list_issues(scope)

    socket
    |> assign(:counts, %{
      organizations: length(organizations),
      projects: length(projects),
      error_logs: length(error_logs)
    })
    |> assign(:stats, calculate_stats(error_logs))
    |> assign(:error_trends, calculate_error_trends(scope))
    |> assign(:status_distribution, calculate_status_distribution(error_logs))
    |> assign(:method_distribution, calculate_method_distribution(error_logs))
    |> assign(:top_projects, calculate_top_projects(projects, error_logs))
    |> assign(
      :setup_progress,
      setup_progress(length(organizations), length(projects), length(error_logs))
    )
    |> assign(:recent_error_logs, Enum.take(error_logs, 5))
  end

  defp calculate_stats(error_logs) do
    open_issues = Enum.count(error_logs, &(&1.status == "open"))
    resolved_issues = Enum.count(error_logs, &(&1.status == "resolved"))

    avg_resolution = calculate_avg_resolution_time(error_logs)

    %{
      open_issues: open_issues,
      resolved_issues: resolved_issues,
      avg_resolution: avg_resolution
    }
  end

  defp calculate_avg_resolution_time(error_logs) do
    resolved_logs = Enum.filter(error_logs, &(&1.status == "resolved" && &1.updated_at))

    if length(resolved_logs) > 0 do
      total_hours =
        resolved_logs
        |> Enum.map(fn log ->
          DateTime.diff(log.updated_at, log.inserted_at, :hour)
        end)
        |> Enum.sum()

      trunc(total_hours / length(resolved_logs))
    else
      0
    end
  end

  defp calculate_error_trends(scope) do
    Tracker.get_error_trends(scope)
  end

  defp calculate_status_distribution(error_logs) do
    distribution =
      Enum.reduce(error_logs, %{open: 0, in_progress: 0, resolved: 0}, fn log, acc ->
        case log.status do
          "open" -> Map.update!(acc, :open, &(&1 + 1))
          "in_progress" -> Map.update!(acc, :in_progress, &(&1 + 1))
          "resolved" -> Map.update!(acc, :resolved, &(&1 + 1))
          _ -> acc
        end
      end)

    # Ensure we have at least some data for visualization
    if Enum.all?(distribution, fn {_, v} -> v == 0 end) do
      %{open: 1, in_progress: 1, resolved: 1}
    else
      distribution
    end
  end

  defp calculate_method_distribution(error_logs) do
    distribution =
      error_logs
      |> Enum.group_by(& &1.method)
      |> Enum.map(fn {method, logs} -> {method, length(logs)} end)
      |> Enum.sort_by(fn {_, count} -> count end, :desc)

    # If no data, provide default
    if distribution == [] do
      [{"GET", 0}, {"POST", 0}, {"PUT", 0}, {"DELETE", 0}]
    else
      distribution
    end
  end

  defp calculate_top_projects(projects, error_logs) do
    # Group errors by project
    project_errors =
      error_logs
      |> Enum.group_by(& &1.project_id)
      |> Enum.map(fn {project_id, logs} ->
        project = Enum.find(projects, &(&1.id == project_id))

        project_data =
          if project do
            project
            |> Map.from_struct()
            # Mock data - replace with actual query
            |> Map.put(:total_requests, 100)
          else
            %{name: "Unknown", total_requests: 100}
          end

        {project_data, length(logs)}
      end)
      |> Enum.sort_by(fn {_, count} -> count end, :desc)
      |> Enum.take(5)

    # If no projects with errors, show some default projects
    if project_errors == [] do
      projects
      |> Enum.take(5)
      |> Enum.map(fn project ->
        project_data =
          project
          |> Map.from_struct()
          |> Map.put(:total_requests, 100)

        {project_data, 0}
      end)
    else
      project_errors
    end
  end

  # Chart helper functions
  defp chart_points(trends, field) do
    trends
    |> Enum.with_index()
    |> Enum.map(fn {{_date, data}, index} ->
      x = 40 + index * 340 / 29
      y = 160 - Map.get(data, field, 0) * 140 / 50
      "#{x},#{y}"
    end)
    |> Enum.join(" ")
  end

  defp x_position(index) do
    40 + index * 340 / 29
  end

  defp y_position(value) do
    # Default to max 50 for now or calculate from trends
    160 - value * 140 / 50
  end

  defp pie_segment(distribution, key) do
    total = Enum.sum(Map.values(distribution))
    value = Map.get(distribution, key, 0)
    percentage = value / total
    circumference = 2 * :math.pi() * 80
    dash_length = circumference * percentage
    "#{dash_length} #{circumference}"
  end

  defp pie_offset(distribution, keys) do
    total = Enum.sum(Map.values(distribution))

    offset_percentage =
      keys
      |> Enum.map(fn key -> Map.get(distribution, key, 0) end)
      |> Enum.sum()
      |> Kernel./(total)

    circumference = 2 * :math.pi() * 80
    offset_length = circumference * offset_percentage
    "-#{offset_length}"
  end

  defp method_percentage(count, total) do
    if total > 0, do: trunc(count / total * 100), else: 0
  end

  defp error_rate(error_count, total_requests) do
    if total_requests > 0, do: Float.round(error_count / total_requests * 100, 1), else: 0.0
  end

  defp method_color("GET"), do: "bg-emerald-500/20 text-[#6EE7B7]"
  defp method_color("POST"), do: "bg-blue-500/20 text-[#93C5FD]"
  defp method_color("PUT"), do: "bg-amber-500/20 text-[#FCD34D]"
  defp method_color("PATCH"), do: "bg-amber-500/20 text-[#FCD34D]"
  defp method_color("DELETE"), do: "bg-red-500/20 text-[#FCA5A5]"
  defp method_color(_), do: "bg-[#374151] text-[#D1D5DB]"

  defp status_color("open"), do: "bg-red-500/20 text-[#FCA5A5]"
  defp status_color("in_progress"), do: "bg-amber-500/20 text-[#FCD34D]"
  defp status_color("resolved"), do: "bg-emerald-500/20 text-[#6EE7B7]"
  defp status_color(_), do: "bg-[#374151] text-[#D1D5DB]"

  defp format_timestamp(dt), do: Calendar.strftime(dt, "%b %d, %H:%M")

  defp setup_progress(org_count, project_count, log_count) do
    completed_steps =
      0
      |> maybe_inc(org_count > 0)
      |> maybe_inc(project_count > 0)
      |> maybe_inc(log_count > 0)

    trunc(completed_steps / 3 * 100)
  end

  defp maybe_inc(value, true), do: value + 1
  defp maybe_inc(value, false), do: value
end
