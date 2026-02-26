defmodule FixitWeb.IssueLive.Show do
  use FixitWeb, :live_view

  alias Fixit.Tracker

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section class="space-y-6">
        <header class="relative overflow-hidden rounded-3xl border border-[#1F2937] bg-[#101827] p-6">
          <div class="absolute -right-20 -top-20 h-56 w-56 rounded-full bg-red-500/10 blur-3xl"></div>
          <div class="absolute -bottom-20 left-1/3 h-56 w-56 rounded-full bg-blue-500/10 blur-3xl">
          </div>
          <div class="relative space-y-4">
            <p class="text-sm text-[#94A3B8]">
              Error Log <span class="mx-2 text-[#64748B]">/</span>
              <span class="font-semibold text-white">{@issue.organization.name}</span>
            </p>
            <div class="flex flex-wrap items-start justify-between gap-4">
              <div>
                <div class="flex items-center gap-2">
                  <span class={"rounded px-2 py-1 text-xs font-bold text-white #{method_bg(@issue.method)}"}>
                    {@issue.method}
                  </span>
                  <h1 class="text-2xl font-black tracking-tight text-white">{@issue.path}</h1>
                </div>
                <p class="mt-2 text-sm text-[#94A3B8]">
                  Last seen {format_timestamp(@issue.updated_at)}
                </p>
              </div>
              <div class="flex flex-wrap items-center gap-2">
                <.link
                  navigate={~p"/issues/#{@issue}/edit?return_to=show"}
                  class="rounded-lg border border-[#334155] bg-[#0F172A] px-3 py-2 text-sm font-semibold text-[#CBD5E1] transition hover:bg-[#162033]"
                >
                  Edit
                </.link>
                <div class="flex items-center gap-3 rounded-xl border border-[#334155] bg-[#0F172A] px-4 py-2">
                  <span class="text-sm font-medium text-[#94a3b8]">Resolved</span>
                  <input
                    type="checkbox"
                    class="toggle toggle-primary toggle-sm"
                    checked={@issue.status == "resolved"}
                    phx-click="set-status"
                    phx-value-status={if @issue.status == "resolved", do: "open", else: "resolved"}
                  />
                </div>
                <button
                  :if={is_nil(@issue.claimed_by_id)}
                  phx-click="claim"
                  class="flex items-center gap-2 rounded-lg bg-[#3b82f6] px-4 py-2 text-sm font-bold text-white transition hover:brightness-110"
                >
                  <.icon name="hero-hand-raised" class="size-4" /> Claim Issue
                </button>
                <button
                  :if={@issue.claimed_by_id == @current_scope.user.id}
                  phx-click="unclaim"
                  class="flex items-center gap-2 rounded-lg border border-[#334155] bg-[#334155]/30 px-4 py-2 text-sm font-bold text-white transition hover:bg-[#334155]/50"
                >
                  <.icon name="hero-hand-raised" class="size-4" /> Unclaim
                </button>
              </div>
            </div>
          </div>
        </header>

        <div class="grid gap-6 lg:grid-cols-[minmax(0,1fr)_320px]">
          <div class="space-y-4">
            <div class="flex flex-wrap gap-2">
              <%= for {label, id} <- [
                {"Overview", "overview"},
                {"Stack Trace", "stack_trace"},
                {"Payload", "payload"},
                {"Headers", "headers"},
                {"Activity", "activity"}
              ] do %>
                <button
                  phx-click="select-tab"
                  phx-value-tab={id}
                  class={[
                    "rounded-lg border px-3 py-2 text-sm font-semibold transition",
                    if(@active_tab == id,
                      do: "border-blue-500/50 bg-blue-500/20 text-blue-200",
                      else: "border-[#334155] bg-[#0F172A] text-[#94A3B8] hover:bg-[#162033]"
                    )
                  ]}
                >
                  {label}
                </button>
              <% end %>
            </div>

            <div class="rounded-2xl border border-[#1F2937] bg-[#0F172A] p-5">
              <%= case @active_tab do %>
                <% "overview" -> %>
                  <div class="space-y-4">
                    <h2 class="text-lg font-semibold text-white">Issue Summary</h2>
                    <p class="text-sm text-[#CBD5E1]">{@issue.description}</p>
                  </div>
                <% "stack_trace" -> %>
                  <div class="space-y-3">
                    <h2 class="text-lg font-semibold text-white">Stack Trace</h2>
                    <pre class="overflow-auto rounded-xl border border-[#334155] bg-[#111827] p-4 font-mono text-xs leading-6 text-[#CBD5E1]">{@issue.stack_trace || "No stack trace provided."}</pre>
                  </div>
                <% "payload" -> %>
                  <div class="space-y-3">
                    <h2 class="text-lg font-semibold text-white">Payload</h2>
                    <pre class="overflow-auto rounded-xl border border-[#334155] bg-[#111827] p-4 font-mono text-xs leading-6 text-[#CBD5E1]">{@issue.payload || "No payload provided."}</pre>
                  </div>
                <% "headers" -> %>
                  <div class="space-y-3">
                    <h2 class="text-lg font-semibold text-white">Headers</h2>
                    <pre class="overflow-auto rounded-xl border border-[#334155] bg-[#111827] p-4 font-mono text-xs leading-6 text-[#CBD5E1]">{@issue.headers || "No headers provided."}</pre>
                  </div>
                <% "activity" -> %>
                  <div class="space-y-3">
                    <h2 class="text-lg font-semibold text-white">Activity</h2>
                    <p class="text-sm text-[#94A3B8]">No recent activity on this issue.</p>
                  </div>
              <% end %>
            </div>
          </div>

          <aside class="space-y-4">
            <section class="rounded-2xl border border-[#1F2937] bg-[#0F172A] p-4">
              <h3 class="text-xs font-semibold uppercase tracking-[0.12em] text-[#94A3B8]">Status</h3>
              <div class="mt-3 flex items-center gap-2">
                <div class={"size-2.5 rounded-full #{status_dot(@issue.status)}"}></div>
                <p class="text-sm font-semibold text-white">
                  {String.replace(@issue.status, "_", " ")}
                </p>
              </div>
            </section>

            <section class="rounded-2xl border border-[#1F2937] bg-[#0F172A] p-4">
              <h3 class="text-xs font-semibold uppercase tracking-[0.12em] text-[#94A3B8]">
                Error Type
              </h3>
              <p class="mt-3 text-sm font-semibold text-white">HTTP {@issue.error_code}</p>
              <p class="mt-1 text-xs text-[#94A3B8]">{@issue.method} {@issue.path}</p>
            </section>

            <section class="rounded-2xl border border-[#1F2937] bg-[#0F172A] p-4">
              <h3 class="text-xs font-semibold uppercase tracking-[0.12em] text-[#94A3B8]">
                Ownership
              </h3>
              <p class="mt-3 text-sm text-[#CBD5E1]">
                <%= if @issue.claimed_by_id do %>
                  Claimed by you
                <% else %>
                  Unassigned
                <% end %>
              </p>
            </section>
          </aside>
        </div>
      </section>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      Tracker.subscribe_issues(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Error Log Details")
     |> assign(:active_tab, "stack_trace")
     |> assign(:issue, Tracker.get_issue!(socket.assigns.current_scope, id))}
  end

  @impl true
  def handle_event("select-tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, tab)}
  end

  def handle_event("set-status", %{"status" => status}, socket) do
    {:ok, issue} =
      Tracker.update_issue_status(socket.assigns.current_scope, socket.assigns.issue, status)

    {:noreply, assign(socket, :issue, issue)}
  end

  def handle_event("claim", _params, socket) do
    case Tracker.claim_issue(socket.assigns.current_scope, socket.assigns.issue) do
      {:ok, issue} ->
        {:noreply, assign(socket, :issue, issue)}

      {:error, :already_claimed} ->
        {:noreply, put_flash(socket, :error, "Issue is already claimed.")}
    end
  end

  def handle_event("unclaim", _params, socket) do
    {:ok, issue} = Tracker.unclaim_issue(socket.assigns.current_scope, socket.assigns.issue)
    {:noreply, assign(socket, :issue, issue)}
  end

  @impl true
  def handle_info(
        {:updated, %Fixit.Tracker.Issue{id: id} = issue},
        %{assigns: %{issue: %{id: id}}} = socket
      ) do
    {:noreply, assign(socket, :issue, issue)}
  end

  def handle_info(
        {:deleted, %Fixit.Tracker.Issue{id: id}},
        %{assigns: %{issue: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "The current error log was deleted.")
     |> push_navigate(to: ~p"/issues")}
  end

  def handle_info({type, %Fixit.Tracker.Issue{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, socket}
  end

  defp format_timestamp(nil), do: "N/A"
  defp format_timestamp(dt), do: Calendar.strftime(dt, "%b %d, %H:%M")

  defp method_bg("GET"), do: "bg-emerald-500/20 text-[#6EE7B7]"
  defp method_bg("POST"), do: "bg-red-500 text-white"
  defp method_bg("PUT"), do: "bg-amber-500/20 text-[#FCD34D]"
  defp method_bg("PATCH"), do: "bg-amber-500/20 text-[#FCD34D]"
  defp method_bg("DELETE"), do: "bg-red-500/20 text-[#FCA5A5]"
  defp method_bg(_), do: "bg-[#374151] text-[#D1D5DB]"

  defp status_dot("open"), do: "bg-[#ef4444]"
  defp status_dot("in_progress"), do: "bg-[#f59e0b]"
  defp status_dot("resolved"), do: "bg-[#22c55e]"
  defp status_dot(_), do: "bg-[#64748b]"
end
