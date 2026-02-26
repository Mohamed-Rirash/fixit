defmodule FixitWeb.UserLive.Login do
  use FixitWeb, :live_view

  alias Fixit.Accounts

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
                class="rounded-md bg-[#3B82F6] px-3 py-2 text-center text-white transition"
              >
                Sign In
              </.link>
              <.link
                navigate={~p"/users/register"}
                class="rounded-md px-3 py-2 text-center text-[#6B7280] transition hover:text-[#F3F4F6]"
              >
                Sign Up
              </.link>
            </div>

            <h1 class="mt-6 text-2xl font-black tracking-tight text-white">Welcome back</h1>
            <p class="mt-2 text-sm text-[#9CA3AF]">
              <%= if @current_scope do %>
                You need to reauthenticate to perform sensitive actions on your account.
              <% else %>
                Please enter your details to sign in.
              <% end %>
            </p>

            <div class="mt-5 space-y-2">
              <button
                type="button"
                class="w-full rounded-lg border border-[#1F2937] bg-transparent px-3 py-2.5 text-sm font-semibold text-[#F3F4F6] transition hover:bg-white/5 active:scale-[0.995]"
              >
                Continue with GitHub
              </button>
              <button
                type="button"
                class="w-full rounded-lg border border-[#1F2937] bg-transparent px-3 py-2.5 text-sm font-semibold text-[#F3F4F6] transition hover:bg-white/5 active:scale-[0.995]"
              >
                Continue with Google
              </button>
            </div>

            <div class="my-5 flex items-center gap-3">
              <div class="h-px flex-1 bg-[#1F2937]"></div>
              <span class="text-xs font-semibold tracking-[0.1em] text-[#6B7280]">OR</span>
              <div class="h-px flex-1 bg-[#1F2937]"></div>
            </div>

            <.form
              for={@form}
              id="login_form_password"
              action={~p"/users/log-in"}
              phx-submit="submit_password"
              phx-trigger-action={@trigger_submit}
              class="space-y-3"
            >
              <.input
                id="login_form_password_email"
                readonly={!!@current_scope}
                field={@form[:email]}
                type="email"
                label="Work Email"
                placeholder="name@company.com"
                autocomplete="email"
                required
                phx-mounted={JS.focus()}
              />
              <.input
                id="login_form_password_password"
                field={@form[:password]}
                type="password"
                label="Password"
                placeholder="********"
                autocomplete="current-password"
              />

              <div class="text-right text-xs">
                <a href="#" class="text-[#9CA3AF] transition hover:text-[#F3F4F6]">
                  Forgot password?
                </a>
              </div>

              <.button
                class="w-full"
                variant="primary"
                name={@form[:remember_me].name}
                value="true"
              >
                Sign In
              </.button>
              <.button class="w-full">Sign in only this time</.button>
            </.form>

            <.form
              for={@form}
              id="login_form_magic"
              action={~p"/users/log-in"}
              phx-submit="submit_magic"
              class="mt-3 space-y-2"
            >
              <.input
                id="login_form_magic_email"
                readonly={!!@current_scope}
                field={@form[:email]}
                type="email"
                label="Email for magic link"
                autocomplete="email"
              />
              <.button class="w-full text-xs">Log in with email</.button>
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
              Need an account?
              <.link
                navigate={~p"/users/register"}
                class="font-semibold text-[#3B82F6] hover:underline"
              >
                Sign up
              </.link>
            </p>
          </div>

          <div
            :if={local_mail_adapter?()}
            class="mt-4 rounded-xl border border-blue-400/30 bg-blue-500/10 p-3 text-xs text-[#9CA3AF]"
          >
            Local mail adapter enabled:
            <.link href="/dev/mailbox" class="font-semibold text-blue-300 underline">
              /dev/mailbox
            </.link>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false)}
  end

  @impl true
  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  def handle_event("submit_magic", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(
        user,
        &url(~p"/users/log-in/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions for logging in shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> push_navigate(to: ~p"/users/log-in")}
  end

  defp local_mail_adapter? do
    Application.get_env(:fixit, Fixit.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
