defmodule FixitWeb.ProjectLive.Form do
  use FixitWeb, :live_view

  alias Fixit.Workspaces
  alias Fixit.Workspaces.Project

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>Set up a project where your team collaborates on API failure logs.</:subtitle>
      </.header>

      <.form for={@form} id="project-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:project_key]} type="text" label="Project key" />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <.input
          field={@form[:organization_id]}
          type="select"
          label="Organization"
          prompt="Select organization"
          options={@organization_options}
        />
        <.input field={@form[:team_id]} type="hidden" />
        <p class="text-xs text-base-content/60">
          Team is auto-assigned from the selected organization.
        </p>
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Project</.button>
          <.button navigate={return_path(@current_scope, @return_to, @project)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    project = Workspaces.get_project!(socket.assigns.current_scope, id)

    socket
    |> assign(:page_title, "Edit Project")
    |> assign(:project, project)
    |> assign_workspace_options(project.organization_id)
    |> assign(:form, to_form(Workspaces.change_project(socket.assigns.current_scope, project)))
  end

  defp apply_action(socket, :new, _params) do
    organization_id =
      case Workspaces.organization_options(socket.assigns.current_scope) do
        [{_label, id} | _] -> id
        _ -> nil
      end

    team_id =
      case Workspaces.team_options(socket.assigns.current_scope, organization_id) do
        [{_label, id} | _] -> id
        _ -> nil
      end

    project = %Project{user_id: socket.assigns.current_scope.user.id}

    socket
    |> assign(:page_title, "New Project")
    |> assign(:project, project)
    |> assign_workspace_options(organization_id)
    |> assign(
      :form,
      to_form(
        Workspaces.change_project(
          socket.assigns.current_scope,
          project,
          %{}
          |> maybe_put_scope_id("organization_id", organization_id)
          |> maybe_put_scope_id("team_id", team_id)
        )
      )
    )
  end

  @impl true
  def handle_event("validate", %{"project" => project_params}, socket) do
    organization_id =
      Map.get(project_params, "organization_id", socket.assigns.project.organization_id)

    team_id =
      case Map.get(project_params, "team_id") do
        team when is_binary(team) and team != "" ->
          team

        _ ->
          case Workspaces.team_options(socket.assigns.current_scope, organization_id) do
            [{_label, id} | _] -> id
            _ -> nil
          end
      end

    changeset =
      Workspaces.change_project(
        socket.assigns.current_scope,
        socket.assigns.project,
        Map.put(project_params, "team_id", team_id)
      )

    {:noreply,
     socket
     |> assign_workspace_options(organization_id)
     |> assign(:form, to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"project" => project_params}, socket) do
    save_project(socket, socket.assigns.live_action, with_default_team_id(socket, project_params))
  end

  defp save_project(socket, :edit, project_params) do
    case Workspaces.update_project(
           socket.assigns.current_scope,
           socket.assigns.project,
           project_params
         ) do
      {:ok, project} ->
        {:noreply,
         socket
         |> put_flash(:info, "Project updated successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, project)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_project(socket, :new, project_params) do
    case Workspaces.create_project(socket.assigns.current_scope, project_params) do
      {:ok, project} ->
        {:noreply,
         socket
         |> put_flash(:info, "Project created successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, project)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path(_scope, "index", _project), do: ~p"/projects"
  defp return_path(_scope, "show", project), do: ~p"/projects/#{project}"

  defp assign_workspace_options(socket, organization_id) do
    _organization_id = organization_id

    socket
    |> assign(
      :organization_options,
      Workspaces.organization_options(socket.assigns.current_scope)
    )
    |> assign(
      :team_options,
      Workspaces.team_options(socket.assigns.current_scope, organization_id)
    )
  end

  defp maybe_put_scope_id(attrs, _field, nil), do: attrs
  defp maybe_put_scope_id(attrs, field, value), do: Map.put(attrs, field, value)

  defp with_default_team_id(socket, project_params) do
    case Map.get(project_params, "team_id") do
      team_id when is_binary(team_id) and team_id != "" ->
        project_params

      _ ->
        organization_id = Map.get(project_params, "organization_id")

        default_team_id =
          case Workspaces.team_options(socket.assigns.current_scope, organization_id) do
            [{_label, id} | _] -> id
            _ -> nil
          end

        maybe_put_scope_id(project_params, "team_id", default_team_id)
    end
  end
end
