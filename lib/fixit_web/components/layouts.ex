defmodule FixitWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use FixitWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  attr :org_context, :map,
    default: nil,
    doc: "optional organization context for sidebar switcher"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <%= if @current_scope do %>
      <div class="min-h-screen bg-[#0B0F17] text-[#F3F4F6]">
        <div class="flex min-h-screen">
          <aside class="hidden w-72 shrink-0 border-r border-[#1F2937] bg-[#111827] lg:flex lg:flex-col">
            <div class="border-b border-[#1F2937] px-5 py-5">
              <p class="text-xl font-black tracking-tight text-white">FixIt</p>
              <p class="mt-1 text-xs text-[#9CA3AF]">Engineering</p>

              <div :if={@org_context} class="mt-4 rounded-lg border border-[#1F2937] bg-[#141C2B] p-3">
                <p class="text-xs font-semibold text-[#F3F4F6]">{@org_context.organization_name}</p>
                <p class="mt-1 text-[11px] text-[#9CA3AF]">{@org_context.team_name}</p>
              </div>
            </div>

            <nav class="flex-1 space-y-1 px-4 py-4">
              <.link
                navigate={~p"/dashboard"}
                class="flex items-center gap-2 rounded-lg px-3 py-2 text-sm font-semibold text-[#F3F4F6] transition hover:bg-white/10"
              >
                <.icon name="hero-home" class="size-4" /> Dashboard
              </.link>
              <.link
                navigate={~p"/issues"}
                class="flex items-center gap-2 rounded-lg px-3 py-2 text-sm font-semibold text-[#F3F4F6] transition hover:bg-white/10"
              >
                <.icon name="hero-bug-ant" class="size-4" /> Error Logs
              </.link>
              <.link
                navigate={~p"/projects"}
                class="flex items-center gap-2 rounded-lg px-3 py-2 text-sm font-semibold text-[#F3F4F6] transition hover:bg-white/10"
              >
                <.icon name="hero-folder" class="size-4" /> Projects
              </.link>
              <.link
                navigate={~p"/organizations"}
                class="flex items-center gap-2 rounded-lg px-3 py-2 text-sm font-semibold text-[#F3F4F6] transition hover:bg-white/10"
              >
                <.icon name="hero-building-office-2" class="size-4" /> Organizations
              </.link>
              <a
                href="#"
                class="flex items-center gap-2 rounded-lg px-3 py-2 text-sm font-semibold text-[#F3F4F6] transition hover:bg-white/10"
              >
                <.icon name="hero-bell" class="size-4" /> Alerts
              </a>
            </nav>

            <div class="space-y-3 border-t border-[#1F2937] p-4">
              <.link
                id="sidebar-profile-link"
                navigate={~p"/users/settings"}
                class="flex items-center gap-3 rounded-lg border border-[#1F2937] bg-[#141C2B] p-3 transition hover:border-[#334155] hover:bg-[#182338]"
              >
                <div class="flex size-9 items-center justify-center rounded-full bg-blue-500/20 text-sm font-bold text-blue-300">
                  {user_initials(@current_scope.user)}
                </div>
                <div class="min-w-0">
                  <p class="truncate text-sm font-semibold text-white">
                    {user_full_name(@current_scope.user)}
                  </p>
                  <p class="truncate text-xs text-[#9CA3AF]">{@current_scope.user.email}</p>
                  <p class="truncate text-[11px] text-[#6B7280]">Admin</p>
                </div>
              </.link>

              <.link
                href={~p"/users/log-out"}
                method="delete"
                class="flex items-center gap-2 rounded-lg px-3 py-2 text-sm font-semibold text-red-300 transition hover:bg-red-500/10"
              >
                <.icon name="hero-arrow-right-start-on-rectangle" class="size-4" /> Log out
              </.link>
            </div>
          </aside>

          <main class="flex-1 px-4 pb-10 pt-6 sm:px-6 lg:px-8">
            <div class="mx-auto w-full max-w-7xl">
              {render_slot(@inner_block)}
            </div>
          </main>
        </div>
      </div>
    <% else %>
      <main class="px-4 pb-20 pt-10 sm:px-6 lg:px-8">
        <div class="mx-auto w-full max-w-6xl">
          {render_slot(@inner_block)}
        </div>
      </main>
    <% end %>
    <.flash_group flash={@flash} />
    """
  end

  defp user_full_name(user) do
    first = user.first_name || ""
    last = user.last_name || ""
    name = String.trim("#{first} #{last}")

    if name == "", do: "User", else: name
  end

  defp user_initials(user) do
    [user.first_name, user.last_name]
    |> Enum.filter(&is_binary/1)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&String.first/1)
    |> Enum.take(2)
    |> Enum.join()
    |> case do
      "" -> "U"
      initials -> String.upcase(initials)
    end
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
