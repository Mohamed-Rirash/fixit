defmodule FixitWeb.ProjectLive.Index do
  use FixitWeb, :live_view

  alias Fixit.Tracker
  alias Fixit.Workspaces

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section class="space-y-6">
        <header class="relative overflow-hidden rounded-3xl border border-[#1F2937] bg-[#101827] p-6">
          <div class="absolute -right-20 -top-20 h-56 w-56 rounded-full bg-indigo-500/10 blur-3xl">
          </div>
          <div class="absolute -bottom-24 left-1/3 h-56 w-56 rounded-full bg-cyan-500/10 blur-3xl">
          </div>
          <div class="relative flex flex-wrap items-start justify-between gap-4">
            <div>
              <p class="text-xs font-semibold uppercase tracking-[0.14em] text-cyan-300">
                Workspace Services
              </p>
              <h1 class="mt-2 text-3xl font-black tracking-tight text-white">Projects</h1>
              <p class="mt-2 text-sm text-[#94A3B8]">
                Each project has its own incident stream, ownership, and team collaboration flow.
              </p>
            </div>
            <.button variant="primary" navigate={~p"/projects/new"}>
              <.icon name="hero-plus" /> New Project
            </.button>
          </div>
        </header>

        <div
          :if={@projects_empty?}
          class="rounded-2xl border border-dashed border-[#334155] bg-[#0F172A] p-8 text-center"
        >
          <h2 class="text-xl font-bold text-white">No projects yet</h2>
          <p class="mt-2 text-sm text-[#94A3B8]">
            Create a project under your organization, then start logging API failures.
          </p>
          <.button variant="primary" navigate={~p"/projects/new"} class="mt-4">
            Create First Project
          </.button>
        </div>

        <div id="projects" phx-update="stream" class="grid gap-4 md:grid-cols-2">
          <article
            :for={{id, project} <- @streams.projects}
            id={id}
            class="rounded-2xl border border-[#1F2937] bg-[#0F172A] p-5 transition hover:border-cyan-400/40"
          >
            <div class="flex items-start justify-between gap-3">
              <div>
                <h2 class="text-lg font-bold tracking-tight text-white">{project.name}</h2>
                <p class="mt-1 text-xs uppercase tracking-[0.12em] text-[#94A3B8]">
                  {project.project_key}
                </p>
              </div>
              <span class="rounded-full bg-indigo-500/15 px-2.5 py-1 text-xs font-semibold text-indigo-300">
                {@error_counts[project.id] || 0} logs
              </span>
            </div>

            <p class="mt-3 text-sm text-[#94A3B8]">{project.description}</p>

            <div class="mt-3 space-y-1 text-xs text-[#94A3B8]">
              <p>Organization: {project.organization && project.organization.name}</p>
              <p>Team: {(project.team && project.team.name) || "Core API Team"}</p>
            </div>

            <div class="mt-4 flex flex-wrap gap-2">
              <.button navigate={~p"/projects/#{project}"}>Open</.button>
              <.button navigate={~p"/projects/#{project}/edit"}>Edit</.button>
              <.button navigate={~p"/issues/new"}>Log Error</.button>
              <button
                type="button"
                phx-click={JS.push("delete", value: %{id: project.id}) |> hide("##{id}")}
                data-confirm="Delete this project?"
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
      Workspaces.subscribe_projects(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Projects")
     |> assign_project_state()}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    project = Workspaces.get_project!(socket.assigns.current_scope, id)
    {:ok, _} = Workspaces.delete_project(socket.assigns.current_scope, project)

    {:noreply, assign_project_state(socket)}
  end

  @impl true
  def handle_info({type, %Fixit.Workspaces.Project{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, assign_project_state(socket)}
  end

  defp assign_project_state(socket) do
    scope = socket.assigns.current_scope
    projects = Workspaces.list_projects(scope)
    error_logs = Tracker.list_issues(scope)

    socket
    |> assign(:error_counts, Enum.frequencies_by(error_logs, & &1.project_id))
    |> assign(:projects_empty?, projects == [])
    |> stream(:projects, projects, reset: true)
  end
end
