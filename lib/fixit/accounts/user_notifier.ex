defmodule Fixit.Accounts.UserNotifier do
  import Swoosh.Email
  alias Fixit.Mailer
  alias Fixit.Accounts.User

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    {from_name, from_email} = sender()

    email =
      new()
      |> to(recipient)
      |> from({from_name, from_email})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  defp sender do
    mailer_config = Application.get_env(:fixit, Fixit.Mailer, [])
    from_name = Keyword.get(mailer_config, :from_name, "Fixit")
    from_email = Keyword.get(mailer_config, :from_email, "no-reply@fixit.local")
    {from_name, from_email}
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    deliver(user.email, "Update email instructions", """

    ==============================

    Hi #{user.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to log in with a magic link.
  """
  def deliver_login_instructions(user, url) do
    case user do
      %User{confirmed_at: nil} -> deliver_confirmation_instructions(user, url)
      _ -> deliver_magic_link_instructions(user, url)
    end
  end

  defp deliver_magic_link_instructions(user, url) do
    deliver(user.email, "Log in instructions", """

    ==============================

    Hi #{user.email},

    You can log into your account by visiting the URL below:

    #{url}

    If you didn't request this email, please ignore this.

    ==============================
    """)
  end

  defp deliver_confirmation_instructions(user, url) do
    deliver(user.email, "Confirmation instructions", """

    ==============================

    Hi #{user.email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end

  @doc """
  Delivers a project invitation email for collaboration.
  """
  def deliver_project_invitation(
        recipient_email,
        inviter_email,
        project_name,
        organization_name,
        url
      )
      when is_binary(recipient_email) and is_binary(inviter_email) and is_binary(url) do
    deliver(recipient_email, "You're invited to collaborate on #{project_name}", """

    ==============================

    Hi #{recipient_email},

    #{inviter_email} invited you to collaborate on "#{project_name}" in #{organization_name}.

    Open this link to continue:

    #{url}

    If you weren't expecting this invitation, you can ignore this email.

    ==============================
    """)
  end
end
