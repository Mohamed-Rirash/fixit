defmodule FixitWeb.ProjectLive.Show do
  use FixitWeb, :live_view

  alias Fixit.Tracker
  alias Fixit.Workspaces

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_scope}
      org_context={
        %{
          organization_name: (@project.organization && @project.organization.name) || "Organization",
          team_name: (@project.team && @project.team.name) || "Engineering Team"
        }
      }
    >
      <section class="space-y-6">
        <div class="relative overflow-hidden rounded-3xl border border-[#1F2937] bg-[#101827] p-6 shadow-lg shadow-black/20">
          <div class="absolute -right-20 -top-20 h-56 w-56 rounded-full bg-indigo-500/10 blur-3xl">
          </div>
          <div class="absolute -bottom-20 left-1/3 h-56 w-56 rounded-full bg-cyan-500/10 blur-3xl">
          </div>
          <div class="relative">
            <p class="text-sm text-[#9CA3AF]">
              Projects <span class="mx-2 text-[#6B7280]">/</span>
              <span class="font-semibold text-[#F3F4F6]">{@project.name}</span>
            </p>

            <div class="mt-4 flex flex-wrap items-start justify-between gap-4">
              <div>
                <div class="flex flex-wrap items-center gap-2">
                  <h1 class="text-3xl font-black tracking-tight text-[#F3F4F6]">
                    {if @project.name == "", do: "Payment Gateway API", else: @project.name}
                  </h1>
                  <span class="rounded-full bg-green-500/20 px-2.5 py-1 text-xs font-semibold text-[#22C55E]">
                    PRODUCTION
                  </span>
                </div>
                <p class="mt-2 text-sm text-[#9CA3AF]">
                  ID: proj_{String.slice(@project.id, 0, 6)} • Last deploy: 2h ago
                </p>
              </div>

              <div class="flex flex-wrap items-center gap-2">
                <div class="flex items-center rounded-lg border border-[#1F2937] bg-[#141C2B] p-1 text-xs">
                  <button type="button" class={time_btn_class(@time_filter == "24h")}>24h</button>
                  <button type="button" class={time_btn_class(@time_filter == "7d")}>7d</button>
                  <button type="button" class={time_btn_class(@time_filter == "30d")}>30d</button>
                </div>
                <span class="inline-flex size-8 items-center justify-center rounded-full bg-blue-500/25 text-xs font-semibold text-blue-300">
                  {user_initials(@current_scope.user)}
                </span>
                <.button navigate={~p"/projects/#{@project}/edit?return_to=show"}>
                  <.icon name="hero-pencil-square" class="size-4" /> Edit
                </.button>
              </div>
            </div>
          </div>
        </div>

        <div class="rounded-xl border border-[#1F2937] bg-[#111827]/85 p-6 shadow-lg shadow-black/20">
          <p class="text-sm text-[#9CA3AF]">
            Reliability snapshot for this service.
          </p>
        </div>

        <div class="grid gap-4 md:grid-cols-3">
          <article class="rounded-xl border border-[#1F2937] bg-[#111827]/80 p-5 shadow-lg shadow-black/15">
            <div class="flex items-center justify-between">
              <p class="text-xs uppercase tracking-[0.1em] text-[#9CA3AF]">Total Errors</p>
              <.icon name="hero-exclamation-circle" class="size-5 text-[#EF4444]" />
            </div>
            <p class="mt-3 text-3xl font-black text-[#F3F4F6]">{@metrics.total_errors}</p>
            <p class={delta_class(@metrics.total_delta)}>
              {format_delta(@metrics.total_delta)} vs previous 24h
            </p>
          </article>

          <article class="rounded-xl border border-[#1F2937] bg-[#111827]/80 p-5 shadow-lg shadow-black/15">
            <div class="flex items-center justify-between">
              <p class="text-xs uppercase tracking-[0.1em] text-[#9CA3AF]">Resolved Issues</p>
              <.icon name="hero-check-circle" class="size-5 text-[#22C55E]" />
            </div>
            <p class="mt-3 text-3xl font-black text-[#F3F4F6]">{@metrics.resolved_issues}</p>
            <p class={delta_class(@metrics.resolved_delta)}>
              {format_delta(@metrics.resolved_delta)} vs previous 24h
            </p>
          </article>

          <article class="rounded-xl border border-[#1F2937] bg-[#111827]/80 p-5 shadow-lg shadow-black/15">
            <div class="flex items-center justify-between">
              <p class="text-xs uppercase tracking-[0.1em] text-[#9CA3AF]">Avg Response Time</p>
              <.icon name="hero-clock" class="size-5 text-[#2563EB]" />
            </div>
            <p class="mt-3 text-3xl font-black text-[#F3F4F6]">{@metrics.avg_response_time}ms</p>
            <p class={delta_class(@metrics.response_delta)}>
              {format_delta(@metrics.response_delta)} vs previous 24h
            </p>
          </article>
        </div>

        <section class="rounded-xl border border-[#1F2937] bg-[#111827]/80 p-5 shadow-lg shadow-black/15">
          <h2 class="text-base font-semibold text-[#F3F4F6]">Error Trends</h2>
          <p class="mt-1 text-sm text-[#9CA3AF]">Frequency of 5xx and 4xx errors over time</p>

          <div class="mt-4 overflow-x-auto">
            <svg viewBox="0 0 720 240" class="h-64 w-full min-w-[680px]">
              <defs>
                <linearGradient id="trend-fill" x1="0" x2="0" y1="0" y2="1">
                  <stop offset="0%" stop-color="#2563EB" stop-opacity="0.35" />
                  <stop offset="100%" stop-color="#2563EB" stop-opacity="0.02" />
                </linearGradient>
              </defs>

              <path d={@chart.area_path} fill="url(#trend-fill)" />
              <path
                d={@chart.path_500}
                fill="none"
                stroke="#2563EB"
                stroke-width="3"
                stroke-linecap="round"
                stroke-linejoin="round"
              />
              <path
                d={@chart.path_400}
                fill="none"
                stroke="#F59E0B"
                stroke-width="2.5"
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-dasharray="4 5"
              />

              <circle :for={point <- @chart.points_500} cx={point.x} cy={point.y} r="3" fill="#2563EB">
                <title>500 Errors: {point.value}</title>
              </circle>
              <circle :for={point <- @chart.points_400} cx={point.x} cy={point.y} r="3" fill="#F59E0B">
                <title>400 Errors: {point.value}</title>
              </circle>
            </svg>
          </div>

          <div class="mt-2 flex items-center gap-4 text-xs text-[#9CA3AF]">
            <p class="flex items-center gap-2">
              <span class="h-2 w-2 rounded-full bg-[#2563EB]"></span> 500 Errors
            </p>
            <p class="flex items-center gap-2">
              <span class="h-2 w-2 rounded-full bg-[#F59E0B]"></span> 400 Errors
            </p>
          </div>
        </section>

        <section class="rounded-xl border border-[#1F2937] bg-[#111827]/80 p-5 shadow-lg shadow-black/15">
          <div class="flex items-center justify-between gap-3">
            <h2 class="text-base font-semibold text-[#F3F4F6]">Recent Incidents</h2>
            <.button variant="primary" navigate={~p"/issues/new"}>
              <.icon name="hero-plus" /> Log API Error
            </.button>
          </div>

          <div class="mt-4 overflow-auto rounded-lg border border-[#1F2937]">
            <table class="min-w-full text-sm">
              <thead class="bg-[#141C2B] text-left text-xs uppercase tracking-[0.08em] text-[#9CA3AF]">
                <tr>
                  <th class="px-4 py-3">Status</th>
                  <th class="px-4 py-3">Incident ID / Endpoint</th>
                  <th class="px-4 py-3">Error Type</th>
                  <th class="px-4 py-3">Time</th>
                  <th class="px-4 py-3">Actions</th>
                </tr>
              </thead>
              <tbody>
                <tr
                  :for={issue <- @recent_incidents}
                  class="border-t border-[#1F2937] hover:bg-[#141C2B]/60 transition"
                >
                  <td class="px-4 py-3">
                    <span class={status_badge(issue.status)}>
                      {incident_status(issue.status)}
                    </span>
                  </td>
                  <td class="px-4 py-3">
                    <p class="font-semibold text-[#F3F4F6]">INC-{incident_number(issue.id)}</p>
                    <p class="font-mono text-xs text-[#9CA3AF]">{issue.method} {issue.path}</p>
                  </td>
                  <td class="px-4 py-3 text-[#F3F4F6]">HTTP {issue.error_code}</td>
                  <td class="px-4 py-3 text-[#9CA3AF]">{time_ago(issue.inserted_at)}</td>
                  <td class="px-4 py-3">
                    <.link
                      navigate={~p"/issues/#{issue}"}
                      class="text-xs font-semibold text-[#2563EB] hover:underline"
                    >
                      View
                    </.link>
                  </td>
                </tr>

                <tr :if={@recent_incidents == []}>
                  <td colspan="5" class="px-4 py-6 text-center text-sm text-[#9CA3AF]">
                    No incidents found for this project.
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <div class="mt-3 flex items-center justify-end gap-2 text-xs text-[#9CA3AF]">
            <button type="button" class="rounded border border-[#1F2937] bg-[#141C2B] px-2 py-1">
              Prev
            </button>
            <span>Page 1 of 1</span>
            <button type="button" class="rounded border border-[#1F2937] bg-[#141C2B] px-2 py-1">
              Next
            </button>
          </div>
        </section>

        <div class="grid gap-6 lg:grid-cols-2">
          <section class="rounded-xl border border-[#1F2937] bg-[#111827]/80 p-5">
            <h2 class="text-base font-semibold text-[#F3F4F6]">Project Team</h2>
            <p class="mt-1 text-sm text-[#9CA3AF]">
              Collaborators invited to this project with their access roles.
            </p>
            <div class="mt-4 space-y-2">
              <div
                :if={@memberships == []}
                class="rounded-xl bg-[#141C2B] px-3 py-2 text-sm text-[#9CA3AF]"
              >
                No members yet.
              </div>
              <div
                :for={membership <- @memberships}
                class="flex items-center justify-between rounded-xl border border-[#1F2937] bg-[#141C2B] px-3 py-2"
              >
                <div class="text-sm">
                  <p class="font-semibold text-[#F3F4F6]">{membership.user.email}</p>
                  <p class="text-xs text-[#9CA3AF]">
                    Invited by {membership.invited_by && membership.invited_by.email}
                  </p>
                </div>
                <div class="flex items-center gap-2">
                  <span class="rounded-full bg-[#111827] px-2.5 py-1 text-xs font-semibold uppercase text-[#9CA3AF]">
                    {membership.role}
                  </span>
                  <button
                    :if={membership.user_id != @current_scope.user.id}
                    id={"remove-member-#{membership.id}"}
                    type="button"
                    phx-click="remove_member"
                    phx-value-id={membership.id}
                    class="rounded-md border border-red-500/40 bg-red-500/10 px-2.5 py-1 text-xs font-semibold text-red-300 transition hover:bg-red-500/20"
                  >
                    Remove
                  </button>
                </div>
              </div>
            </div>
          </section>

          <section class="rounded-xl border border-[#1F2937] bg-[#111827]/80 p-5">
            <h2 class="text-base font-semibold text-[#F3F4F6]">Invite Collaborator</h2>
            <p class="mt-1 text-sm text-[#9CA3AF]">
              Invite by email. They can register first, then be added to this project.
            </p>
            <.form
              for={@invite_form}
              id="project-invite-form"
              phx-submit="invite"
              class="mt-4 space-y-3"
            >
              <.input field={@invite_form[:email]} type="email" label="Email" required />
              <.input
                field={@invite_form[:role]}
                type="select"
                label="Role"
                options={[{"Collaborator", "collaborator"}, {"Admin", "admin"}]}
              />
              <.button variant="primary" class="w-full">Send Invite</.button>
            </.form>
          </section>
        </div>
      </section>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      Workspaces.subscribe_projects(socket.assigns.current_scope)
      Tracker.subscribe_issues(socket.assigns.current_scope)
    end

    project = Workspaces.get_project!(socket.assigns.current_scope, id)

    {:ok,
     socket
     |> assign(:page_title, "Project Details")
     |> assign(:project, project)
     |> assign(
       :memberships,
       Workspaces.list_project_members(socket.assigns.current_scope, project)
     )
     |> assign(:time_filter, "24h")
     |> assign_project_dashboard(project.id)
     |> assign(:invite_form, to_form(%{"email" => "", "role" => "collaborator"}, as: :invite))}
  end

  @impl true
  def handle_event("invite", %{"invite" => %{"email" => email, "role" => role}}, socket) do
    case Workspaces.invite_project_member(
           socket.assigns.current_scope,
           socket.assigns.project,
           email,
           role
         ) do
      {:ok, :invite_email_sent} ->
        {:noreply,
         socket
         |> put_flash(
           :info,
           "Invite email sent. They can register from the link and will be added to this project after confirming email."
         )
         |> assign(:invite_form, to_form(%{"email" => "", "role" => role}, as: :invite))}

      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Collaborator invited.")
         |> assign(
           :memberships,
           Workspaces.list_project_members(socket.assigns.current_scope, socket.assigns.project)
         )
         |> assign_project_dashboard(socket.assigns.project.id)
         |> assign(:invite_form, to_form(%{"email" => "", "role" => role}, as: :invite))}

      {:error, :user_not_found} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "No user found for that email. Ask them to register first, then invite again."
         )}

      {:error, :email_delivery_failed} ->
        {:noreply, put_flash(socket, :error, "Invitation email could not be sent right now.")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Unable to invite user.")}
    end
  end

  def handle_event("remove_member", %{"id" => membership_id}, socket) do
    case Workspaces.remove_project_member(
           socket.assigns.current_scope,
           socket.assigns.project,
           membership_id
         ) do
      {:ok, _membership} ->
        {:noreply,
         socket
         |> put_flash(:info, "Collaborator removed.")
         |> assign(
           :memberships,
           Workspaces.list_project_members(socket.assigns.current_scope, socket.assigns.project)
         )}

      {:error, :cannot_remove_self} ->
        {:noreply, put_flash(socket, :error, "You cannot remove yourself from this project.")}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, "Collaborator was not found.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Unable to remove collaborator.")}
    end
  end

  @impl true
  def handle_info(
        {:updated, %Fixit.Workspaces.Project{id: id} = project},
        %{assigns: %{project: %{id: id}}} = socket
      ) do
    {:noreply, assign(socket, :project, project)}
  end

  def handle_info(
        {:deleted, %Fixit.Workspaces.Project{id: id}},
        %{assigns: %{project: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "The current project was deleted.")
     |> push_navigate(to: ~p"/projects")}
  end

  def handle_info({type, %Fixit.Workspaces.Project{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, socket}
  end

  def handle_info(
        {type, %Fixit.Tracker.Issue{project_id: project_id}},
        %{assigns: %{project: %{id: project_id}}} = socket
      )
      when type in [:created, :updated, :deleted] do
    {:noreply, assign_project_dashboard(socket, project_id)}
  end

  def handle_info({type, %Fixit.Tracker.Issue{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, socket}
  end

  defp project_error_logs(scope, project_id) do
    Tracker.list_issues(scope, %{"project_id" => project_id})
  end

  defp assign_project_dashboard(socket, project_id) do
    issues = project_error_logs(socket.assigns.current_scope, project_id)
    recent_incidents = Enum.take(issues, 10)
    metrics = build_metrics(issues)
    chart = build_chart_series(issues)

    socket
    |> assign(:error_logs, issues)
    |> assign(:recent_incidents, recent_incidents)
    |> assign(:metrics, metrics)
    |> assign(:chart, chart)
  end

  defp build_metrics(issues) do
    now = DateTime.utc_now()
    day_ago = DateTime.add(now, -24 * 60 * 60, :second)
    two_days_ago = DateTime.add(now, -48 * 60 * 60, :second)

    current_24h = Enum.count(issues, &(DateTime.compare(&1.inserted_at, day_ago) == :gt))

    previous_24h =
      Enum.count(issues, fn issue ->
        DateTime.compare(issue.inserted_at, two_days_ago) == :gt and
          DateTime.compare(issue.inserted_at, day_ago) != :gt
      end)

    resolved_current =
      Enum.count(issues, fn issue ->
        issue.status == "resolved" and DateTime.compare(issue.updated_at, day_ago) == :gt
      end)

    resolved_previous =
      Enum.count(issues, fn issue ->
        issue.status == "resolved" and
          DateTime.compare(issue.updated_at, two_days_ago) == :gt and
          DateTime.compare(issue.updated_at, day_ago) != :gt
      end)

    avg_response_time =
      case issues do
        [] ->
          0

        _ ->
          issues
          |> Enum.map(fn issue -> max(120, issue.error_code * 2) end)
          |> Enum.sum()
          |> Kernel./(length(issues))
          |> round()
      end

    %{
      total_errors: length(issues),
      total_delta: percent_delta(current_24h, previous_24h),
      resolved_issues: Enum.count(issues, &(&1.status == "resolved")),
      resolved_delta: percent_delta(resolved_current, resolved_previous),
      avg_response_time: avg_response_time,
      response_delta: percent_delta(avg_response_time, max(120, avg_response_time + 60))
    }
  end

  defp percent_delta(current, previous) do
    cond do
      previous <= 0 and current <= 0 -> 0
      previous <= 0 -> 100
      true -> round((current - previous) / previous * 100)
    end
  end

  defp build_chart_series(issues) do
    now = DateTime.utc_now()
    width = 680
    height = 180
    step_hours = 4

    buckets =
      for index <- 0..5 do
        bucket_end = DateTime.add(now, -index * step_hours * 60 * 60, :second)
        bucket_start = DateTime.add(bucket_end, -step_hours * 60 * 60, :second)

        bucket_issues =
          Enum.filter(issues, fn issue ->
            DateTime.compare(issue.inserted_at, bucket_start) == :gt and
              DateTime.compare(issue.inserted_at, bucket_end) != :gt
          end)

        %{
          errors_500: Enum.count(bucket_issues, &(&1.error_code >= 500)),
          errors_400: Enum.count(bucket_issues, &(&1.error_code >= 400 and &1.error_code < 500))
        }
      end
      |> Enum.reverse()

    values_500 = Enum.map(buckets, & &1.errors_500)
    values_400 = Enum.map(buckets, & &1.errors_400)

    max_value =
      [Enum.max(values_500, fn -> 0 end), Enum.max(values_400, fn -> 0 end), 1]
      |> Enum.max()

    points_500 = series_points(values_500, width, height, max_value)
    points_400 = series_points(values_400, width, height, max_value)

    %{
      points_500: points_500,
      points_400: points_400,
      path_500: line_path(points_500),
      path_400: line_path(points_400),
      area_path: area_path(points_500, height)
    }
  end

  defp series_points(values, width, height, max_value) do
    step_x = width / max(length(values) - 1, 1)

    values
    |> Enum.with_index()
    |> Enum.map(fn {value, index} ->
      x = round(index * step_x)
      y = round(height - value / max_value * (height - 10))
      %{x: x, y: y, value: value}
    end)
  end

  defp line_path([]), do: ""

  defp line_path([first | rest]) do
    "M #{first.x} #{first.y} " <>
      Enum.map_join(rest, " ", fn point -> "L #{point.x} #{point.y}" end)
  end

  defp area_path([], _height), do: ""

  defp area_path(points, height) do
    first = hd(points)
    last = List.last(points)

    line_path(points) <>
      " L #{last.x} #{height} L #{first.x} #{height} Z"
  end

  defp incident_status("open"), do: "Open"
  defp incident_status("in_progress"), do: "In Progress"
  defp incident_status("resolved"), do: "Resolved"
  defp incident_status(_), do: "Open"

  defp status_badge("open"),
    do: "rounded-full bg-red-500/20 px-2 py-1 text-xs font-semibold text-[#EF4444]"

  defp status_badge("in_progress"),
    do: "rounded-full bg-amber-500/20 px-2 py-1 text-xs font-semibold text-[#F59E0B]"

  defp status_badge("resolved"),
    do: "rounded-full bg-green-500/20 px-2 py-1 text-xs font-semibold text-[#22C55E]"

  defp status_badge(_),
    do: "rounded-full bg-zinc-500/20 px-2 py-1 text-xs font-semibold text-[#9CA3AF]"

  defp time_ago(timestamp) do
    diff_minutes = DateTime.diff(DateTime.utc_now(), timestamp, :minute)

    cond do
      diff_minutes < 1 -> "just now"
      diff_minutes < 60 -> "#{diff_minutes} mins ago"
      diff_minutes < 1_440 -> "#{div(diff_minutes, 60)} hours ago"
      true -> "#{div(diff_minutes, 1_440)} days ago"
    end
  end

  defp incident_number(id) do
    id
    |> String.replace("-", "")
    |> String.slice(0, 4)
    |> String.upcase()
  end

  defp time_btn_class(true), do: "rounded bg-[#2563EB] px-2 py-1 font-semibold text-white"

  defp time_btn_class(false),
    do:
      "rounded px-2 py-1 font-semibold text-[#9CA3AF] transition hover:bg-white/10 hover:text-[#F3F4F6]"

  defp format_delta(delta) when delta > 0, do: "+#{delta}%"
  defp format_delta(delta), do: "#{delta}%"

  defp delta_class(delta) do
    base = "mt-2 text-xs "

    cond do
      delta > 0 -> base <> "text-[#22C55E]"
      delta < 0 -> base <> "text-[#EF4444]"
      true -> base <> "text-[#9CA3AF]"
    end
  end

  defp user_initials(user) do
    [user.first_name, user.last_name]
    |> Enum.filter(&is_binary/1)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&String.first/1)
    |> Enum.take(2)
    |> Enum.join()
    |> case do
      "" -> "U"
      initials -> String.upcase(initials)
    end
  end
end
