defmodule FixitWeb.OrganizationLive.Index do
  use FixitWeb, :live_view

  alias Fixit.Tracker
  alias Fixit.Workspaces

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section class="space-y-6">
        <header class="relative overflow-hidden rounded-3xl border border-[#1F2937] bg-[#101827] p-6">
          <div class="absolute -right-20 -top-20 h-56 w-56 rounded-full bg-cyan-500/10 blur-3xl">
          </div>
          <div class="absolute -bottom-24 left-1/3 h-56 w-56 rounded-full bg-blue-500/10 blur-3xl">
          </div>
          <div class="relative flex flex-wrap items-start justify-between gap-4">
            <div>
              <p class="text-xs font-semibold uppercase tracking-[0.14em] text-cyan-300">
                Workspace Hub
              </p>
              <h1 class="mt-2 text-3xl font-black tracking-tight text-white">Organizations</h1>
              <p class="mt-2 max-w-2xl text-sm text-[#94A3B8]">
                Manage organizations as top-level boundaries for projects, members, and API incidents.
              </p>
            </div>
            <.button variant="primary" navigate={~p"/organizations/new"}>
              <.icon name="hero-plus" /> New Organization
            </.button>
          </div>
        </header>

        <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          <article class="rounded-2xl border border-[#1F2937] bg-[#0F172A] p-4">
            <p class="text-xs uppercase tracking-[0.12em] text-[#94A3B8]">Organizations</p>
            <p class="mt-2 text-2xl font-black text-white">{@counts.organizations}</p>
          </article>
          <article class="rounded-2xl border border-[#1F2937] bg-[#0F172A] p-4">
            <p class="text-xs uppercase tracking-[0.12em] text-[#94A3B8]">Projects</p>
            <p class="mt-2 text-2xl font-black text-white">{@counts.projects}</p>
          </article>
          <article class="rounded-2xl border border-[#1F2937] bg-[#0F172A] p-4">
            <p class="text-xs uppercase tracking-[0.12em] text-[#94A3B8]">Error Logs</p>
            <p class="mt-2 text-2xl font-black text-white">{@counts.error_logs}</p>
          </article>
        </div>

        <div
          :if={@organizations_empty?}
          class="rounded-2xl border border-dashed border-[#334155] bg-[#0F172A] p-8 text-center"
        >
          <h2 class="text-xl font-bold text-white">No organizations yet</h2>
          <p class="mt-2 text-sm text-[#94A3B8]">
            Create your first organization, then add a project and start logging API failures.
          </p>
          <.button variant="primary" navigate={~p"/organizations/new"} class="mt-4">
            Create First Organization
          </.button>
        </div>

        <div id="organizations" phx-update="stream" class="grid gap-4 md:grid-cols-2">
          <article
            :for={{id, organization} <- @streams.organizations}
            id={id}
            class="rounded-2xl border border-[#1F2937] bg-[#0F172A] p-5 transition hover:border-cyan-400/40"
          >
            <div class="flex items-start justify-between gap-3">
              <div>
                <h2 class="text-lg font-bold tracking-tight text-white">{organization.name}</h2>
                <p class="mt-1 text-xs uppercase tracking-[0.12em] text-[#94A3B8]">
                  {organization.slug}
                </p>
              </div>
              <span class="rounded-full bg-cyan-500/15 px-2.5 py-1 text-xs font-semibold text-cyan-300">
                {@project_counts[organization.id] || 0} projects
              </span>
            </div>

            <p class="mt-3 text-sm text-[#94A3B8]">
              {@error_counts[organization.id] || 0} total error logs in this organization.
            </p>

            <div class="mt-4 flex flex-wrap gap-2">
              <.button navigate={~p"/organizations/#{organization}"}>Open</.button>
              <.button navigate={~p"/organizations/#{organization}/edit"}>Edit</.button>
              <.button navigate={~p"/projects/new"}>New Project</.button>
              <button
                type="button"
                phx-click={JS.push("delete", value: %{id: organization.id}) |> hide("##{id}")}
                data-confirm="Delete this organization?"
                class="rounded-lg border border-rose-300 bg-rose-50 px-3 py-2 text-sm font-semibold text-rose-700 transition hover:bg-rose-100"
              >
                Delete
              </button>
            </div>
          </article>
        </div>
      </section>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Workspaces.subscribe_organizations(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Organizations")
     |> assign_workspace_state()}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    organization = Workspaces.get_organization!(socket.assigns.current_scope, id)
    {:ok, _} = Workspaces.delete_organization(socket.assigns.current_scope, organization)

    {:noreply, assign_workspace_state(socket)}
  end

  @impl true
  def handle_info({type, %Fixit.Workspaces.Organization{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, assign_workspace_state(socket)}
  end

  defp assign_workspace_state(socket) do
    scope = socket.assigns.current_scope
    organizations = Workspaces.list_organizations(scope)
    projects = Workspaces.list_projects(scope)
    error_logs = Tracker.list_issues(scope)

    project_counts = Enum.frequencies_by(projects, & &1.organization_id)
    error_counts = Enum.frequencies_by(error_logs, & &1.organization_id)

    socket
    |> assign(:counts, %{
      organizations: length(organizations),
      projects: length(projects),
      error_logs: length(error_logs)
    })
    |> assign(:project_counts, project_counts)
    |> assign(:error_counts, error_counts)
    |> assign(:organizations_empty?, organizations == [])
    |> stream(:organizations, organizations, reset: true)
  end
end
