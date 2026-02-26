defmodule FixitWeb.IssueLive.Index do
  use FixitWeb, :live_view

  alias Fixit.Tracker

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section class="space-y-5">
        <div class="border-b border-[#1F2937] pb-4">
          <div class="flex flex-wrap items-center justify-between gap-3">
            <div class="flex items-center gap-3">
              <h1 class="text-2xl font-black tracking-tight text-[#F8FAFC]">Error Tracking</h1>
              <span class="inline-flex items-center gap-1 rounded-md border border-[#1E3A8A] bg-[#1E3A8A]/30 px-2 py-1 text-xs font-semibold text-[#BFDBFE]">
                <span class="size-1.5 animate-pulse rounded-full bg-[#60A5FA]"></span> Live
              </span>
              <p class="text-sm text-[#94A3B8]">Last 24h</p>
            </div>

            <div class="flex items-center gap-2">
              <label class="hidden text-xs font-semibold uppercase tracking-[0.08em] text-[#64748B] sm:block">
                Search
              </label>
              <div class="relative">
                <.icon
                  name="hero-magnifying-glass"
                  class="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-[#64748B]"
                />
                <input
                  type="text"
                  placeholder="Search error logs, trace ID..."
                  class="w-64 rounded-lg border border-[#334155] bg-[#111827] py-2 pl-9 pr-3 text-sm text-[#E2E8F0] placeholder:text-[#64748B] outline-none transition focus:border-[#3B82F6] sm:w-80"
                />
              </div>
            </div>
          </div>
        </div>

        <div class="flex flex-wrap items-start justify-between gap-4">
          <div>
            <h2 class="text-3xl font-black tracking-tight text-[#F8FAFC]">Error Logs</h2>
            <p class="mt-1 text-base text-[#94A3B8]">Real-time API failure monitoring and triage.</p>
          </div>

          <div class="flex flex-wrap items-center gap-2">
            <button
              type="button"
              class="inline-flex items-center gap-2 rounded-lg border border-[#334155] bg-[#111827] px-4 py-2 text-sm font-semibold text-[#E2E8F0] transition hover:border-[#475569] hover:bg-[#172033]"
            >
              <.icon name="hero-arrow-down-tray" class="size-4" /> Export CSV
            </button>
            <button
              type="button"
              class="inline-flex items-center gap-2 rounded-lg border border-[#1D4ED8] bg-[#1D4ED8] px-4 py-2 text-sm font-semibold text-white transition hover:bg-[#1E40AF]"
            >
              <.icon name="hero-arrow-path" class="size-4" /> Refresh
            </button>
            <.button variant="primary" navigate={~p"/issues/new"} id="new-issue">
              <.icon name="hero-plus" class="size-4" /> Log API Error
            </.button>
          </div>
        </div>

        <div class="flex flex-wrap items-center gap-2 border-b border-[#1F2937] pb-4">
          <.link
            patch={
              ~p"/issues?status=open&organization_id=#{@organization_filter}&project_id=#{@project_filter}"
            }
            class={filter_class(@status_filter == "open")}
            id="filter-open"
          >
            Status: Open
          </.link>
          <.link
            patch={
              ~p"/issues?status=all&organization_id=#{@organization_filter}&project_id=#{@project_filter}"
            }
            class={filter_class(@status_filter == "all")}
            id="filter-all"
          >
            Severity: All
          </.link>
          <.link
            patch={
              ~p"/issues?status=#{@status_filter}&organization_id=#{@organization_filter}&project_id=all"
            }
            class={filter_class(@project_filter == "all")}
          >
            Method: All
          </.link>
          <.link
            patch={
              ~p"/issues?status=in_progress&organization_id=#{@organization_filter}&project_id=#{@project_filter}"
            }
            class={filter_class(@status_filter == "in_progress")}
            id="filter-in-progress"
          >
            + Add Filter
          </.link>

          <.link
            patch={~p"/issues?status=all&organization_id=all&project_id=all"}
            class="ml-1 text-sm font-semibold text-[#94A3B8] transition hover:text-[#F3F4F6]"
          >
            Clear all
          </.link>
        </div>

        <div class="overflow-x-auto rounded-2xl border border-[#1F2937] bg-[#0F172A] shadow-inner shadow-black/20">
          <table class="w-full min-w-[1120px] table-fixed">
            <thead class="sticky top-0 z-10 border-b border-[#1F2937] bg-[#111827]/95 backdrop-blur">
              <tr class="text-left text-xs uppercase tracking-[0.09em] text-[#94A3B8]">
                <th class="px-5 py-3 font-semibold">Issue</th>
                <th class="px-5 py-3 font-semibold">Status</th>
                <th class="px-5 py-3 font-semibold">Method</th>
                <th class="px-5 py-3 font-semibold">When</th>
                <th class="px-5 py-3 font-semibold">Assignee</th>
                <th class="px-5 py-3 font-semibold text-right">Actions</th>
              </tr>
            </thead>

            <tbody id="issues" phx-update="stream" class="divide-y divide-[#1F2937]">
              <tr :if={@issues_empty?} id="issues-empty">
                <td colspan="6" class="px-5 py-12 text-center">
                  <div class="mx-auto flex max-w-sm flex-col items-center gap-2">
                    <.icon name="hero-inbox" class="size-8 text-[#475569]" />
                    <p class="text-sm font-semibold text-[#CBD5E1]">No issues match these filters.</p>
                    <p class="text-xs text-[#94A3B8]">
                      Try clearing filters or logging a new API error.
                    </p>
                  </div>
                </td>
              </tr>

              <tr
                :for={{id, issue} <- @streams.issues}
                id={id}
                class="text-sm transition odd:bg-[#0D1728]/60 hover:bg-[#111B2E]"
              >
                <td class="px-5 py-4 align-top">
                  <div class="space-y-1">
                    <p class="max-w-[20rem] truncate font-semibold text-[#F8FAFC]">{issue.path}</p>
                    <p class="max-w-[20rem] truncate text-xs text-[#94A3B8]">
                      {error_type_label(issue)}
                    </p>
                    <p class="text-[11px] text-[#64748B]">HTTP {issue.error_code || 0}</p>
                  </div>
                </td>
                <td class="px-5 py-4 align-top">
                  <span class={status_class(issue.status, issue.error_code)}>
                    {human_status(issue.status)}
                  </span>
                </td>
                <td class="px-5 py-4 align-top">
                  <span class={method_class(issue.method)}>{issue.method}</span>
                </td>
                <td class="px-5 py-4 align-top text-[#94A3B8]">
                  {format_timestamp(issue.inserted_at)}
                </td>
                <td class="px-5 py-4 align-top">
                  <%= if is_nil(issue.claimed_by_id) do %>
                    <span class="text-sm italic text-[#64748B]">Unassigned</span>
                  <% else %>
                    <span class="inline-flex size-8 items-center justify-center rounded-full bg-[#7C3AED] text-xs font-black text-white">
                      {assignee_initials(issue, @current_scope.user.id)}
                    </span>
                  <% end %>
                </td>
                <td class="px-5 py-4 align-top">
                  <div class="flex flex-wrap justify-end gap-1.5">
                    <button
                      :if={issue.status != "resolved"}
                      type="button"
                      phx-click="set-status"
                      phx-value-id={issue.id}
                      phx-value-status="resolved"
                      class="rounded-md border border-[#166534] bg-[#052E16] px-2 py-1 text-xs font-semibold text-[#86EFAC] transition hover:bg-[#064E25]"
                    >
                      Resolve
                    </button>
                    <button
                      :if={is_nil(issue.claimed_by_id)}
                      type="button"
                      phx-click="claim"
                      phx-value-id={issue.id}
                      class="rounded-md border border-[#1E3A8A] bg-[#172554] px-2 py-1 text-xs font-semibold text-[#93C5FD] transition hover:bg-[#1E3A8A]"
                    >
                      Claim
                    </button>
                    <button
                      :if={issue.claimed_by_id == @current_scope.user.id}
                      type="button"
                      phx-click="unclaim"
                      phx-value-id={issue.id}
                      class="rounded-md border border-[#4B5563] bg-[#111827] px-2 py-1 text-xs font-semibold text-[#D1D5DB] transition hover:bg-[#1F2937]"
                    >
                      Unclaim
                    </button>
                    <.link
                      navigate={~p"/issues/#{issue}"}
                      class="rounded-md border border-[#374151] bg-[#0F172A] px-2 py-1 text-xs font-semibold text-[#D1D5DB] transition hover:border-[#64748B] hover:text-white"
                    >
                      Details
                    </.link>
                    <.link
                      navigate={~p"/issues/#{issue}/edit"}
                      class="rounded-md border border-[#374151] bg-[#0F172A] px-2 py-1 text-xs font-semibold text-[#D1D5DB] transition hover:border-[#64748B] hover:text-white"
                    >
                      Edit
                    </.link>
                    <button
                      type="button"
                      phx-click={JS.push("delete", value: %{id: issue.id}) |> hide("##{id}")}
                      data-confirm="Delete this error log?"
                      class="rounded-md border border-[#7F1D1D] bg-[#450A0A] px-2 py-1 text-xs font-semibold text-[#FCA5A5] transition hover:bg-[#5A1111]"
                    >
                      Delete
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="flex flex-wrap items-center justify-between gap-3 border-t border-[#1F2937] pt-4 text-sm">
          <p class="text-[#94A3B8]">
            Showing {Enum.sum(Map.values(@counts))} issues • Open: {@counts.open} • In Progress: {@counts.in_progress} • Resolved: {@counts.resolved}
          </p>
          <p class="text-[#64748B]">Table view • rows update in real time</p>
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

    {:ok,
     socket
     |> assign(:page_title, "Error Log Dashboard")
     |> assign(:status_filter, "all")
     |> assign(:organization_filter, "all")
     |> assign(:project_filter, "all")
     |> assign(:issues_empty?, true)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    status_filter = Map.get(params, "status", "all")
    organization_filter = Map.get(params, "organization_id", "all")
    project_filter = Map.get(params, "project_id", "all")

    project_options = Tracker.project_options(socket.assigns.current_scope, organization_filter)

    issues =
      Tracker.list_issues(socket.assigns.current_scope, %{
        "status" => status_filter,
        "organization_id" => organization_filter,
        "project_id" => project_filter
      })

    counts = issue_counts(socket.assigns.current_scope)

    {:noreply,
     socket
     |> assign(:status_filter, status_filter)
     |> assign(:organization_filter, organization_filter)
     |> assign(:project_filter, project_filter)
     |> assign(:organization_options, Tracker.organization_options(socket.assigns.current_scope))
     |> assign(:project_options, project_options)
     |> assign(:counts, counts)
     |> assign(:issues_empty?, issues == [])
     |> stream(:issues, issues, reset: true)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    issue = Tracker.get_issue!(socket.assigns.current_scope, id)
    {:ok, _} = Tracker.delete_issue(socket.assigns.current_scope, issue)

    {:noreply, socket}
  end

  def handle_event("set-status", %{"id" => id, "status" => status}, socket) do
    issue = Tracker.get_issue!(socket.assigns.current_scope, id)
    {:ok, _issue} = Tracker.update_issue_status(socket.assigns.current_scope, issue, status)

    {:noreply, socket}
  end

  def handle_event("claim", %{"id" => id}, socket) do
    issue = Tracker.get_issue!(socket.assigns.current_scope, id)

    case Tracker.claim_issue(socket.assigns.current_scope, issue) do
      {:ok, _issue} ->
        {:noreply, socket}

      {:error, :already_claimed} ->
        {:noreply, put_flash(socket, :error, "Issue is already claimed.")}
    end
  end

  def handle_event("unclaim", %{"id" => id}, socket) do
    issue = Tracker.get_issue!(socket.assigns.current_scope, id)
    {:ok, _issue} = Tracker.unclaim_issue(socket.assigns.current_scope, issue)
    {:noreply, socket}
  end

  @impl true
  def handle_info({type, %Fixit.Tracker.Issue{}}, socket)
      when type in [:created, :updated, :deleted] do
    issues =
      Tracker.list_issues(socket.assigns.current_scope, %{
        "status" => socket.assigns.status_filter,
        "organization_id" => socket.assigns.organization_filter,
        "project_id" => socket.assigns.project_filter
      })

    {:noreply,
     socket
     |> assign(:counts, issue_counts(socket.assigns.current_scope))
     |> assign(:issues_empty?, issues == [])
     |> stream(:issues, issues, reset: true)}
  end

  defp issue_counts(scope) do
    issues = Tracker.list_issues(scope)

    Enum.reduce(issues, %{open: 0, in_progress: 0, resolved: 0}, fn issue, acc ->
      case issue.status do
        "open" -> Map.update!(acc, :open, &(&1 + 1))
        "in_progress" -> Map.update!(acc, :in_progress, &(&1 + 1))
        "resolved" -> Map.update!(acc, :resolved, &(&1 + 1))
        _ -> acc
      end
    end)
  end

  defp filter_class(true),
    do:
      "rounded-lg border border-[#1E3A8A] bg-[#1E3A8A]/30 px-3 py-2 text-xs font-semibold text-[#BFDBFE]"

  defp filter_class(false),
    do:
      "rounded-lg border border-[#4B5563] bg-[#111827] px-3 py-2 text-xs font-semibold text-[#D1D5DB]"

  defp method_class("GET"),
    do: "rounded-md bg-emerald-500/20 px-2 py-1 text-xs font-bold text-[#6EE7B7]"

  defp method_class("POST"),
    do: "rounded-md bg-blue-500/20 px-2 py-1 text-xs font-bold text-[#93C5FD]"

  defp method_class("PUT"),
    do: "rounded-md bg-amber-500/20 px-2 py-1 text-xs font-bold text-[#FCD34D]"

  defp method_class("PATCH"),
    do: "rounded-md bg-amber-500/20 px-2 py-1 text-xs font-bold text-[#FCD34D]"

  defp method_class("DELETE"),
    do: "rounded-md bg-red-500/20 px-2 py-1 text-xs font-bold text-[#FCA5A5]"

  defp method_class(_), do: "rounded-md bg-[#374151] px-2 py-1 text-xs font-bold text-[#D1D5DB]"

  defp status_class("resolved", _),
    do: "rounded-md bg-emerald-500/20 px-2 py-1 text-xs font-bold uppercase text-[#6EE7B7]"

  defp status_class("in_progress", _),
    do: "rounded-md bg-amber-500/20 px-2 py-1 text-xs font-bold uppercase text-[#FCD34D]"

  defp status_class("open", error_code) when is_integer(error_code) and error_code >= 500,
    do: "rounded-md bg-red-500/20 px-2 py-1 text-xs font-bold uppercase text-[#FCA5A5]"

  defp status_class("open", _),
    do: "rounded-md bg-yellow-500/20 px-2 py-1 text-xs font-bold uppercase text-[#FCD34D]"

  defp status_class(_, _),
    do: "rounded-md bg-red-500/20 px-2 py-1 text-xs font-bold uppercase text-[#FCA5A5]"

  defp human_status("open"), do: "open"
  defp human_status("in_progress"), do: "in progress"
  defp human_status("resolved"), do: "resolved"
  defp human_status(_), do: "open"

  defp error_type_label(issue) do
    case issue.description do
      nil -> "APIError (unknown)"
      "" -> "APIError (unknown)"
      text -> text
    end
  end

  defp format_timestamp(dt), do: Calendar.strftime(dt, "%b %d, %H:%M:%S")

  defp assignee_initials(issue, current_user_id) do
    if issue.claimed_by_id == current_user_id, do: "JD", else: "AK"
  end
end
