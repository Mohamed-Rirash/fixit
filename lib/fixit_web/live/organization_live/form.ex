defmodule FixitWeb.OrganizationLive.Form do
  use FixitWeb, :live_view

  alias Fixit.Workspaces
  alias Fixit.Workspaces.Organization

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>Create a workspace boundary for projects, members, and API error logs.</:subtitle>
      </.header>

      <.form for={@form} id="organization-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:slug]} type="text" label="Slug" />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Organization</.button>
          <.button navigate={return_path(@current_scope, @return_to, @organization)}>Cancel</.button>
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
    organization = Workspaces.get_organization!(socket.assigns.current_scope, id)

    socket
    |> assign(:page_title, "Edit Organization")
    |> assign(:organization, organization)
    |> assign(
      :form,
      to_form(Workspaces.change_organization(socket.assigns.current_scope, organization))
    )
  end

  defp apply_action(socket, :new, _params) do
    organization = %Organization{user_id: socket.assigns.current_scope.user.id}

    socket
    |> assign(:page_title, "New Organization")
    |> assign(:organization, organization)
    |> assign(
      :form,
      to_form(Workspaces.change_organization(socket.assigns.current_scope, organization))
    )
  end

  @impl true
  def handle_event("validate", %{"organization" => organization_params}, socket) do
    changeset =
      Workspaces.change_organization(
        socket.assigns.current_scope,
        socket.assigns.organization,
        organization_params
      )

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"organization" => organization_params}, socket) do
    save_organization(socket, socket.assigns.live_action, organization_params)
  end

  defp save_organization(socket, :edit, organization_params) do
    case Workspaces.update_organization(
           socket.assigns.current_scope,
           socket.assigns.organization,
           organization_params
         ) do
      {:ok, organization} ->
        {:noreply,
         socket
         |> put_flash(:info, "Organization updated successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, organization)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_organization(socket, :new, organization_params) do
    case Workspaces.create_organization(socket.assigns.current_scope, organization_params) do
      {:ok, organization} ->
        {:noreply,
         socket
         |> put_flash(:info, "Organization created successfully")
         |> push_navigate(
           to: return_path(socket.assigns.current_scope, socket.assigns.return_to, organization)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path(_scope, "index", _organization), do: ~p"/organizations"
  defp return_path(_scope, "show", organization), do: ~p"/organizations/#{organization}"
end
