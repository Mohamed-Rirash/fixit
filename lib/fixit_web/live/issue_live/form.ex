defmodule FixitWeb.IssueLive.Form do
  use FixitWeb, :live_view

  alias Fixit.Tracker
  alias Fixit.Tracker.Issue

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section class="mx-auto max-w-4xl space-y-6">
        <.header>
          {@page_title}
          <:subtitle>
            Capture complete failure context so teammates can reproduce and fix quickly.
          </:subtitle>
        </.header>

        <div class="rounded-3xl border border-base-300 bg-base-100 p-6">
          <.form for={@form} id="issue-form" phx-change="validate" phx-submit="save">
            <div class="grid gap-4 sm:grid-cols-2">
              <.input
                field={@form[:organization_id]}
                type="select"
                label="Organization"
                prompt="Select organization"
                options={@organization_options}
              />
              <.input
                field={@form[:project_id]}
                type="select"
                label="Project"
                prompt="Select project"
                options={@project_options}
              />
              <.input
                field={@form[:method]}
                type="select"
                label="HTTP Method"
                prompt="Select method"
                options={issue_method_options()}
              />
              <.input
                field={@form[:status]}
                type="select"
                label="Status"
                options={issue_status_options()}
              />
            </div>

            <.input
              field={@form[:path]}
              type="text"
              label="Endpoint Path"
              placeholder="/api/v1/users"
            />
            <.input field={@form[:error_code]} type="number" label="Error Code" placeholder="500" />
            <.input field={@form[:description]} type="textarea" label="What happened?" rows="4" />

            <div class="grid gap-4 md:grid-cols-2">
              <.input
                field={@form[:payload]}
                type="textarea"
                label="Payload"
                rows="10"
                class="w-full rounded-xl border border-base-300 bg-base-100 px-3 py-2.5 font-mono text-xs outline-none transition focus:border-cyan-500 focus:ring-2 focus:ring-cyan-500/20"
              />
              <.input
                field={@form[:error_response]}
                type="textarea"
                label="Error Response"
                rows="10"
                class="w-full rounded-xl border border-base-300 bg-base-100 px-3 py-2.5 font-mono text-xs outline-none transition focus:border-cyan-500 focus:ring-2 focus:ring-cyan-500/20"
              />
            </div>

            <div class="grid gap-4 md:grid-cols-2">
              <.input
                field={@form[:headers]}
                type="textarea"
                label="Headers"
                rows="10"
                class="w-full rounded-xl border border-base-300 bg-base-100 px-3 py-2.5 font-mono text-xs outline-none transition focus:border-cyan-500 focus:ring-2 focus:ring-cyan-500/20"
              />
              <.input
                field={@form[:stack_trace]}
                type="textarea"
                label="Backend Stack Trace"
                rows="10"
                class="w-full rounded-xl border border-base-300 bg-base-100 px-3 py-2.5 font-mono text-xs outline-none transition focus:border-cyan-500 focus:ring-2 focus:ring-cyan-500/20"
              />
            </div>

            <footer class="mt-6 flex flex-col gap-2 sm:flex-row">
              <.button phx-disable-with="Saving..." variant="primary">Save Error Log</.button>
              <.button navigate={return_path(@current_scope, @return_to, @issue)}>Cancel</.button>
            </footer>
          </.form>
        </div>
      </section>
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
    issue = Tracker.get_issue!(socket.assigns.current_scope, id)

    socket
    |> assign(:page_title, "Edit Error Ticket")
    |> assign(:issue, issue)
    |> assign_workspace_options(issue)
    |> assign(:form, to_form(Tracker.change_issue(socket.assigns.current_scope, issue)))
  end

  defp apply_action(socket, :new, _params) do
    {organization_id, project_id} = default_scope_ids(socket.assigns.current_scope)

    issue = %Issue{
      user_id: socket.assigns.current_scope.user.id,
      status: "open",
      organization_id: organization_id,
      project_id: project_id
    }

    socket
    |> assign(:page_title, "Log New API Error")
    |> assign(:issue, issue)
    |> assign_workspace_options(issue)
    |> assign(:form, to_form(Tracker.change_issue(socket.assigns.current_scope, issue)))
  end

  @impl true
  def handle_event("validate", %{"issue" => issue_params}, socket) do
    organization_id =
      Map.get(issue_params, "organization_id", socket.assigns.issue.organization_id)

    changeset =
      Tracker.change_issue(socket.assigns.current_scope, socket.assigns.issue, issue_params)

    {:noreply,
     socket
     |> assign_workspace_options(socket.assigns.issue, organization_id)
     |> assign(:form, to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"issue" => issue_params}, socket) do
    save_issue(socket, socket.assigns.live_action, issue_params)
  end

  defp save_issue(socket, :edit, issue_params) do
    case Tracker.update_issue(socket.assigns.current_scope, socket.assigns.issue, issue_params) do
      {:ok, issue} ->
        {:noreply,
         socket
         |> put_flash(:info, "Error log updated successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, issue)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_issue(socket, :new, issue_params) do
    case Tracker.create_issue(socket.assigns.current_scope, issue_params) do
      {:ok, issue} ->
        {:noreply,
         socket
         |> put_flash(:info, "Error log created successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, issue)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp issue_method_options do
    Enum.map(Issue.methods(), &{&1, &1})
  end

  defp issue_status_options do
    [
      {"Open", "open"},
      {"In Progress", "in_progress"},
      {"Resolved", "resolved"}
    ]
  end

  defp return_path(_scope, "index", _issue), do: ~p"/issues"
  defp return_path(_scope, "show", issue), do: ~p"/issues/#{issue}"

  defp assign_workspace_options(socket, issue, organization_id_override \\ nil) do
    organization_options = Tracker.organization_options(socket.assigns.current_scope)
    _organization_id = organization_id_override || issue.organization_id
    project_options = Tracker.project_options(socket.assigns.current_scope)

    socket
    |> assign(:organization_options, organization_options)
    |> assign(:project_options, project_options)
  end

  defp default_scope_ids(scope) do
    case Tracker.organization_options(scope) do
      [{_label, organization_id} | _] ->
        case Tracker.project_options(scope, organization_id) do
          [{_project_label, project_id} | _] -> {organization_id, project_id}
          _ -> {organization_id, nil}
        end

      _ ->
        {nil, nil}
    end
  end
end
