defmodule FixitWeb.UserLive.Registration do
  use FixitWeb, :live_view

  alias Fixit.Accounts
  alias Fixit.Accounts.User
  alias Fixit.Workspaces

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="relative mx-auto w-full max-w-2xl">
        <div class="pointer-events-none absolute inset-0 -z-10 bg-[radial-gradient(circle_at_top,rgba(59,130,246,0.22),transparent_45%)]">
        </div>
        <div class="mx-auto w-full max-w-[420px]">
          <div class="mb-6 text-center">
            <div class="mx-auto inline-flex rounded-xl bg-blue-500/20 p-2 text-blue-300">
              <.icon name="hero-bug-ant" class="size-5" />
            </div>
            <p class="mt-2 text-xl font-black tracking-tight text-white">FixIt</p>
            <p class="mt-1 text-sm text-[#9CA3AF]">Track API failures together with your team.</p>
          </div>

          <div class="rounded-xl border border-[#1F2937] bg-[#111827] p-8 shadow-2xl shadow-black/30">
            <div class="grid grid-cols-2 rounded-lg border border-[#1F2937] bg-[#0B1220] p-1 text-sm font-semibold">
              <.link
                navigate={~p"/users/log-in"}
                class="rounded-md px-3 py-2 text-center text-[#6B7280] transition hover:text-[#F3F4F6]"
              >
                Sign In
              </.link>
              <.link
                navigate={~p"/users/register"}
                class="rounded-md bg-[#3B82F6] px-3 py-2 text-center text-white transition"
              >
                Sign Up
              </.link>
            </div>

            <h1 class="mt-6 text-2xl font-black tracking-tight text-white">Register</h1>
            <p class="mt-2 text-sm text-[#9CA3AF]">Please enter your details to sign up.</p>

            <.form
              for={@form}
              id="registration_form"
              phx-submit="save"
              phx-change="validate"
              class="mt-5 space-y-3"
            >
              <input :if={@invite_token} type="hidden" name="invite" value={@invite_token} />
              <.input
                field={@form[:first_name]}
                type="text"
                label="First name"
                autocomplete="given-name"
                required
                phx-mounted={JS.focus()}
              />
              <.input
                field={@form[:last_name]}
                type="text"
                label="Last name"
                autocomplete="family-name"
                required
              />
              <.input
                field={@form[:email]}
                type="email"
                label="Work Email"
                placeholder="name@company.com"
                autocomplete="username"
                readonly={is_binary(@invite_email)}
                required
              />
              <.input
                field={@form[:password]}
                type="password"
                label="Password"
                placeholder="********"
                autocomplete="new-password"
                required
              />
              <.input
                field={@form[:password_confirmation]}
                type="password"
                label="Confirm password"
                placeholder="********"
                autocomplete="new-password"
                required
              />

              <.button phx-disable-with="Creating account..." class="w-full" variant="primary">
                Create an account
              </.button>
            </.form>

            <p class="mt-5 text-center text-xs text-[#6B7280]">
              By continuing, you agree to FixIt's Terms of Service and Privacy Policy.
            </p>
            <p class="mt-2 text-center text-xs text-[#6B7280]">
              <a href="#" class="hover:text-[#F3F4F6]">Documentation</a>
              <span class="mx-2">•</span>
              <a href="#" class="hover:text-[#F3F4F6]">Support</a>
            </p>
            <p class="mt-4 text-center text-sm text-[#9CA3AF]">
              Already registered?
              <.link navigate={~p"/users/log-in"} class="font-semibold text-[#3B82F6] hover:underline">
                Log in
              </.link>
            </p>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_scope: %{user: user}}} = socket)
      when not is_nil(user) do
    {:ok, redirect(socket, to: FixitWeb.UserAuth.signed_in_path(socket))}
  end

  def mount(params, _session, socket) do
    invite = get_invite_from_params(params)
    initial_email = invite && invite.email

    changeset =
      Accounts.change_user_registration(%User{}, maybe_email_params(initial_email),
        validate_unique: false,
        hash_password: false
      )

    {:ok,
     socket
     |> assign(:invite_token, params["invite"])
     |> assign(:invite_email, initial_email)
     |> assign_form(changeset), temporary_assigns: [form: nil]}
  end

  @impl true
  def handle_event("save", %{"user" => user_params} = params, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        return_to = accept_project_invites_and_return_to(user)

        {:ok, _} =
          Accounts.deliver_login_instructions(
            user,
            &magic_link_url(&1, return_to)
          )

        {:noreply,
         socket
         |> put_flash(
           :info,
           "An email was sent to #{user.email}, please access it to confirm your account."
         )
         |> push_navigate(to: ~p"/users/log-in")}

      {:error, %Ecto.Changeset{} = changeset} ->
        invite_token = Map.get(params, "invite")
        {:noreply, socket |> assign(:invite_token, invite_token) |> assign_form(changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      Accounts.change_user_registration(%User{}, user_params,
        validate_unique: false,
        hash_password: false
      )

    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")
    assign(socket, form: form)
  end

  defp maybe_email_params(nil), do: %{}
  defp maybe_email_params(email), do: %{"email" => email}

  defp get_invite_from_params(%{"invite" => token}) when is_binary(token) do
    Workspaces.get_project_invite_by_token(token)
  end

  defp get_invite_from_params(_params), do: nil

  defp accept_project_invites_and_return_to(user) do
    case Workspaces.accept_project_invites_for_user(user) do
      {:ok, [%{project_id: project_id} | _]} -> ~p"/projects/#{project_id}"
      _ -> nil
    end
  end

  defp magic_link_url(token, nil), do: url(~p"/users/log-in/#{token}")

  defp magic_link_url(token, return_to),
    do: url(~p"/users/log-in/#{token}?return_to=#{return_to}")
end
