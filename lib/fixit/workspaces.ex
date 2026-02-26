defmodule Fixit.Workspaces do
  @moduledoc """
  The Workspaces context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Changeset
  alias Fixit.Accounts
  alias Fixit.Accounts.UserNotifier
  alias Fixit.Accounts.User
  alias Fixit.Accounts.Scope
  alias Fixit.Repo
  alias FixitWeb.Endpoint

  alias Fixit.Workspaces.{
    Organization,
    OrganizationMembership,
    Project,
    ProjectInvite,
    ProjectMembership,
    Team
  }

  ## Organizations

  def subscribe_organizations(%Scope{} = scope) do
    Phoenix.PubSub.subscribe(Fixit.PubSub, "user:#{scope.user.id}:organizations")
  end

  defp broadcast_organization(%Scope{} = scope, message) do
    Phoenix.PubSub.broadcast(Fixit.PubSub, "user:#{scope.user.id}:organizations", message)
  end

  def list_organizations(%Scope{} = scope) do
    member_org_ids_query =
      from(m in OrganizationMembership,
        where: m.user_id == ^scope.user.id,
        select: m.organization_id
      )

    Organization
    |> where([o], o.user_id == ^scope.user.id or o.id in subquery(member_org_ids_query))
    |> order_by([o], asc: o.name)
    |> distinct(true)
    |> Repo.all()
  end

  def get_organization!(%Scope{} = scope, id) do
    member_org_ids_query =
      from(m in OrganizationMembership,
        where: m.user_id == ^scope.user.id,
        select: m.organization_id
      )

    Organization
    |> where(
      [o],
      o.id == ^id and (o.user_id == ^scope.user.id or o.id in subquery(member_org_ids_query))
    )
    |> Repo.one!()
  end

  def create_organization(%Scope{} = scope, attrs) do
    Repo.transact(fn ->
      with {:ok, organization = %Organization{}} <-
             %Organization{}
             |> Organization.changeset(attrs, scope)
             |> Repo.insert(),
           {:ok, _default_team} <-
             %Team{}
             |> Team.changeset(
               %{
                 name: "#{organization.name} Core API Team",
                 role: "backend",
                 organization_id: organization.id
               },
               scope
             )
             |> Repo.insert(),
           {:ok, _membership} <-
             %OrganizationMembership{}
             |> OrganizationMembership.changeset(%{
               organization_id: organization.id,
               user_id: scope.user.id,
               role: "owner"
             })
             |> Repo.insert() do
        {:ok, organization}
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
    |> case do
      {:ok, organization} ->
        broadcast_organization(scope, {:created, organization})
        {:ok, organization}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def update_organization(%Scope{} = scope, %Organization{} = organization, attrs) do
    true = organization.user_id == scope.user.id

    with {:ok, organization = %Organization{}} <-
           organization
           |> Organization.changeset(attrs, scope)
           |> Repo.update() do
      broadcast_organization(scope, {:updated, organization})
      {:ok, organization}
    end
  end

  def delete_organization(%Scope{} = scope, %Organization{} = organization) do
    true = organization.user_id == scope.user.id

    with {:ok, organization = %Organization{}} <- Repo.delete(organization) do
      broadcast_organization(scope, {:deleted, organization})
      {:ok, organization}
    end
  end

  def change_organization(%Scope{} = scope, %Organization{} = organization, attrs \\ %{}) do
    true = organization.user_id == scope.user.id
    Organization.changeset(organization, attrs, scope)
  end

  ## Teams

  def subscribe_teams(%Scope{} = scope) do
    Phoenix.PubSub.subscribe(Fixit.PubSub, "user:#{scope.user.id}:teams")
  end

  defp broadcast_team(%Scope{} = scope, message) do
    Phoenix.PubSub.broadcast(Fixit.PubSub, "user:#{scope.user.id}:teams", message)
  end

  def list_teams(%Scope{} = scope) do
    Team
    |> where([t], t.user_id == ^scope.user.id)
    |> order_by([t], asc: t.name)
    |> preload(:organization)
    |> Repo.all()
  end

  def get_team!(%Scope{} = scope, id) do
    Team
    |> where([t], t.id == ^id and t.user_id == ^scope.user.id)
    |> preload(:organization)
    |> Repo.one!()
  end

  def create_team(%Scope{} = scope, attrs) do
    with {:ok, team = %Team{}} <-
           %Team{}
           |> Team.changeset(attrs, scope)
           |> validate_organization_scope(scope)
           |> Repo.insert() do
      broadcast_team(scope, {:created, team})
      {:ok, Repo.preload(team, :organization)}
    end
  end

  def update_team(%Scope{} = scope, %Team{} = team, attrs) do
    true = team.user_id == scope.user.id

    with {:ok, team = %Team{}} <-
           team
           |> Team.changeset(attrs, scope)
           |> validate_organization_scope(scope)
           |> Repo.update() do
      broadcast_team(scope, {:updated, team})
      {:ok, Repo.preload(team, :organization)}
    end
  end

  def delete_team(%Scope{} = scope, %Team{} = team) do
    true = team.user_id == scope.user.id

    with {:ok, team = %Team{}} <- Repo.delete(team) do
      broadcast_team(scope, {:deleted, team})
      {:ok, team}
    end
  end

  def change_team(%Scope{} = scope, %Team{} = team, attrs \\ %{}) do
    true = team.user_id == scope.user.id
    Team.changeset(team, attrs, scope)
  end

  ## Projects

  def subscribe_projects(%Scope{} = scope) do
    Phoenix.PubSub.subscribe(Fixit.PubSub, "user:#{scope.user.id}:projects")
  end

  defp broadcast_project(%Scope{} = scope, message) do
    Phoenix.PubSub.broadcast(Fixit.PubSub, "user:#{scope.user.id}:projects", message)
  end

  def list_projects(%Scope{} = scope) do
    member_project_ids_query =
      from(pm in ProjectMembership,
        where: pm.user_id == ^scope.user.id,
        select: pm.project_id
      )

    Project
    |> where([p], p.user_id == ^scope.user.id or p.id in subquery(member_project_ids_query))
    |> order_by([p], asc: p.name)
    |> preload([:organization, :team])
    |> distinct(true)
    |> Repo.all()
  end

  def get_project!(%Scope{} = scope, id) do
    member_project_ids_query =
      from(pm in ProjectMembership,
        where: pm.user_id == ^scope.user.id,
        select: pm.project_id
      )

    Project
    |> where(
      [p],
      p.id == ^id and (p.user_id == ^scope.user.id or p.id in subquery(member_project_ids_query))
    )
    |> preload([:organization, :team])
    |> Repo.one!()
  end

  def create_project(%Scope{} = scope, attrs) do
    Repo.transact(fn ->
      with {:ok, project = %Project{}} <-
             %Project{}
             |> Project.changeset(attrs, scope)
             |> validate_organization_scope(scope)
             |> validate_team_scope(scope)
             |> validate_team_matches_organization()
             |> Repo.insert(),
           {:ok, _membership} <-
             %ProjectMembership{}
             |> ProjectMembership.changeset(%{
               project_id: project.id,
               user_id: scope.user.id,
               role: "admin",
               invited_by_id: scope.user.id
             })
             |> Repo.insert() do
        {:ok, project}
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
    |> case do
      {:ok, project} ->
        broadcast_project(scope, {:created, project})
        {:ok, Repo.preload(project, [:organization, :team])}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def update_project(%Scope{} = scope, %Project{} = project, attrs) do
    true = project_admin?(scope, project.id)

    with {:ok, project = %Project{}} <-
           project
           |> Project.changeset(attrs, scope)
           |> validate_organization_scope(scope)
           |> validate_team_scope(scope)
           |> validate_team_matches_organization()
           |> Repo.update() do
      broadcast_project(scope, {:updated, project})
      {:ok, Repo.preload(project, [:organization, :team])}
    end
  end

  def delete_project(%Scope{} = scope, %Project{} = project) do
    true = project_admin?(scope, project.id)

    with {:ok, project = %Project{}} <- Repo.delete(project) do
      broadcast_project(scope, {:deleted, project})
      {:ok, project}
    end
  end

  def change_project(%Scope{} = scope, %Project{} = project, attrs \\ %{}) do
    true = is_nil(project.id) or project_member?(scope, project.id)
    Project.changeset(project, attrs, scope)
  end

  def organization_options(%Scope{} = scope) do
    list_organizations(scope) |> Enum.map(&{&1.name, &1.id})
  end

  def team_options(%Scope{} = scope) do
    list_teams(scope) |> Enum.map(&{&1.name, &1.id})
  end

  def team_options(%Scope{} = scope, organization_id) when is_binary(organization_id) do
    Team
    |> where([t], t.user_id == ^scope.user.id and t.organization_id == ^organization_id)
    |> order_by([t], asc: t.name)
    |> Repo.all()
    |> Enum.map(&{&1.name, &1.id})
  end

  def team_options(%Scope{} = scope, _organization_id), do: team_options(scope)

  defp validate_organization_scope(changeset, %Scope{} = scope) do
    organization_id = Changeset.get_field(changeset, :organization_id)

    cond do
      is_nil(organization_id) ->
        changeset

      Repo.get_by(Organization, id: organization_id) &&
          (Repo.get_by(Organization, id: organization_id, user_id: scope.user.id) ||
             organization_member?(scope, organization_id)) ->
        changeset

      true ->
        Changeset.add_error(changeset, :organization_id, "is invalid")
    end
  end

  defp validate_team_scope(changeset, %Scope{} = scope) do
    team_id = Changeset.get_field(changeset, :team_id)

    cond do
      is_nil(team_id) ->
        changeset

      Repo.get_by(Team, id: team_id, user_id: scope.user.id) ->
        changeset

      true ->
        Changeset.add_error(changeset, :team_id, "is invalid")
    end
  end

  defp validate_team_matches_organization(changeset) do
    organization_id = Changeset.get_field(changeset, :organization_id)
    team_id = Changeset.get_field(changeset, :team_id)

    cond do
      is_nil(organization_id) or is_nil(team_id) ->
        changeset

      Repo.get_by(Team, id: team_id, organization_id: organization_id) ->
        changeset

      true ->
        Changeset.add_error(changeset, :team_id, "must belong to the selected organization")
    end
  end

  def invite_project_member(%Scope{} = scope, %Project{} = project, email, role \\ "collaborator")
      when is_binary(email) do
    true = project_admin?(scope, project.id)

    case Accounts.get_user_by_email(email) do
      nil ->
        with {:ok, token} <- create_project_invite(scope, project, email, role),
             {:ok, _email} <-
               UserNotifier.deliver_project_invitation(
                 email,
                 scope.user.email,
                 project.name,
                 (project.organization && project.organization.name) || "your organization",
                 Endpoint.url() <> "/users/register?invite=#{token}"
               ) do
          {:ok, :invite_email_sent}
        else
          {:error, _reason} -> {:error, :email_delivery_failed}
        end

      user ->
        Repo.transact(fn ->
          with {:ok, membership} <-
                 %ProjectMembership{}
                 |> ProjectMembership.changeset(%{
                   project_id: project.id,
                   user_id: user.id,
                   role: role,
                   invited_by_id: scope.user.id
                 })
                 |> Repo.insert(
                   on_conflict: [
                     set: [
                       role: role,
                       invited_by_id: scope.user.id,
                       updated_at: DateTime.utc_now(:second)
                     ]
                   ],
                   conflict_target: [:project_id, :user_id]
                 ),
               {:ok, _email} <-
                 UserNotifier.deliver_project_invitation(
                   user.email,
                   scope.user.email,
                   project.name,
                   (project.organization && project.organization.name) || "your organization",
                   Endpoint.url() <> "/projects/#{project.id}"
                 ) do
            {:ok, membership}
          else
            {:error, %Ecto.Changeset{} = changeset} -> Repo.rollback(changeset)
            {:error, _reason} -> Repo.rollback(:email_delivery_failed)
          end
        end)
        |> case do
          {:ok, membership} -> {:ok, membership}
          {:error, reason} -> {:error, reason}
        end
    end
  end

  def get_project_invite_by_token(token) when is_binary(token) do
    with {:ok, decoded} <- Base.url_decode64(token, padding: false) do
      token_hash = :crypto.hash(:sha256, decoded)

      ProjectInvite
      |> where([invite], invite.token_hash == ^token_hash and is_nil(invite.accepted_at))
      |> preload(project: [:organization, :team])
      |> Repo.one()
    else
      _ -> nil
    end
  end

  def accept_project_invites_for_user(%User{} = user) do
    now = DateTime.utc_now(:second)

    invites =
      ProjectInvite
      |> where([invite], invite.email == ^user.email and is_nil(invite.accepted_at))
      |> Repo.all()

    if invites == [] do
      {:ok, []}
    else
      Repo.transact(fn ->
        accepted_invites =
          Enum.reduce_while(invites, [], fn invite, accepted ->
            membership_attrs = %{
              project_id: invite.project_id,
              user_id: user.id,
              role: invite.role,
              invited_by_id: invite.invited_by_id
            }

            case %ProjectMembership{}
                 |> ProjectMembership.changeset(membership_attrs)
                 |> Repo.insert(
                   on_conflict: [
                     set: [
                       role: invite.role,
                       invited_by_id: invite.invited_by_id,
                       updated_at: now
                     ]
                   ],
                   conflict_target: [:project_id, :user_id]
                 ) do
              {:ok, _membership} ->
                case invite |> Ecto.Changeset.change(accepted_at: now) |> Repo.update() do
                  {:ok, updated_invite} -> {:cont, [updated_invite | accepted]}
                  {:error, _changeset} -> {:halt, Repo.rollback(:invite_accept_failed)}
                end

              {:error, _changeset} ->
                {:halt, Repo.rollback(:invite_membership_failed)}
            end
          end)

        {:ok, Enum.reverse(accepted_invites)}
      end)
      |> case do
        {:ok, accepted_invites} -> {:ok, accepted_invites}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  def list_project_members(%Scope{} = scope, %Project{} = project) do
    true = project_member?(scope, project.id)

    ProjectMembership
    |> where([pm], pm.project_id == ^project.id)
    |> join(:inner, [pm], u in User, on: u.id == pm.user_id)
    |> order_by([pm, u], asc: pm.role, asc: u.email)
    |> preload([pm], [:user, :invited_by])
    |> Repo.all()
  end

  def remove_project_member(%Scope{} = scope, %Project{} = project, membership_id)
      when is_binary(membership_id) do
    true = project_admin?(scope, project.id)

    membership =
      ProjectMembership
      |> where([pm], pm.id == ^membership_id and pm.project_id == ^project.id)
      |> Repo.one()

    cond do
      is_nil(membership) ->
        {:error, :not_found}

      membership.user_id == scope.user.id ->
        {:error, :cannot_remove_self}

      true ->
        Repo.delete(membership)
    end
  end

  def list_organization_members(%Scope{} = scope, %Organization{} = organization) do
    true =
      organization.user_id == scope.user.id or
        organization_member?(scope, organization.id)

    OrganizationMembership
    |> where([m], m.organization_id == ^organization.id)
    |> join(:inner, [m], u in User, on: u.id == m.user_id)
    |> order_by([m, u], asc: m.role, asc: u.email)
    |> preload([m], [:user])
    |> Repo.all()
  end

  def project_member?(%Scope{} = scope, project_id) do
    Repo.exists?(
      from(pm in ProjectMembership,
        where: pm.project_id == ^project_id and pm.user_id == ^scope.user.id
      )
    ) ||
      Repo.exists?(from(p in Project, where: p.id == ^project_id and p.user_id == ^scope.user.id))
  end

  def project_admin?(%Scope{} = scope, project_id) do
    Repo.exists?(
      from(pm in ProjectMembership,
        where:
          pm.project_id == ^project_id and pm.user_id == ^scope.user.id and pm.role == "admin"
      )
    ) ||
      Repo.exists?(from(p in Project, where: p.id == ^project_id and p.user_id == ^scope.user.id))
  end

  def organization_member?(%Scope{} = scope, organization_id) do
    Repo.exists?(
      from(m in OrganizationMembership,
        where: m.organization_id == ^organization_id and m.user_id == ^scope.user.id
      )
    )
  end

  defp create_project_invite(%Scope{} = scope, %Project{} = project, email, role) do
    token = :crypto.strong_rand_bytes(32)
    token_hash = :crypto.hash(:sha256, token)
    encoded_token = Base.url_encode64(token, padding: false)

    %ProjectInvite{}
    |> ProjectInvite.changeset(%{
      email: email,
      role: role,
      token_hash: token_hash,
      project_id: project.id,
      invited_by_id: scope.user.id
    })
    |> Repo.insert()
    |> case do
      {:ok, _invite} -> {:ok, encoded_token}
      {:error, changeset} -> {:error, changeset}
    end
  end
end
