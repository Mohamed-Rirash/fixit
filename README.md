# Fixit

To start your Phoenix server:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Gmail Email Sending (SMTP)

The app can send real emails through Gmail SMTP when these env vars are set:

```bash
export GMAIL_SMTP_USERNAME="your-account@gmail.com"
export GMAIL_SMTP_PASSWORD="your-gmail-app-password"
export GMAIL_SMTP_PORT="587"
export MAIL_FROM_NAME="Fixit"
export MAIL_FROM_EMAIL="your-account@gmail.com"
```

Notes:

* `GMAIL_SMTP_PASSWORD` must be a Gmail App Password (not your normal account password).
* If `GMAIL_SMTP_USERNAME` or `GMAIL_SMTP_PASSWORD` are missing, the app falls back to the local dev mailer adapter.

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
