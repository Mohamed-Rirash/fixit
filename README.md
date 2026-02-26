# FixIt

FixIt is a Phoenix LiveView application for collaborative API incident tracking.
It helps teams log failures, assign ownership, and move incidents from `open` to `resolved` in a shared workspace.

## Features

- User authentication (registration, login, magic link confirmation, account settings)
- Organization and project workspaces
- Error/issue logging with rich payload context
- Status workflow: `open` -> `in_progress` -> `resolved`
- Claim and unclaim ownership of issues
- Project collaboration with email invitations
- Dashboard onboarding flow for new users

## Tech Stack

- Elixir + Phoenix 1.8
- Phoenix LiveView
- Ecto + SQLite (`ecto_sqlite3`)
- Swoosh for email delivery
- Tailwind CSS + esbuild

## Project Structure

- `lib/fixit/accounts` authentication, user tokens, notifications
- `lib/fixit/workspaces` organizations, teams, projects, memberships, invites
- `lib/fixit/tracker` issue lifecycle and filtering
- `lib/fixit_web/live` LiveView screens and interactions
- `config/` environment/runtime config
- `docs/project_prd_and_workflow.md` product requirements and roadmap

## Getting Started

### Prerequisites

- Elixir `~> 1.15`
- Erlang/OTP compatible with your Elixir install

### Setup

```bash
mix setup
```

This installs dependencies, creates the DB, runs migrations, and builds assets.

### Run the App

```bash
mix phx.server
```

Open [http://localhost:4000](http://localhost:4000).

### Test and Quality Checks

```bash
mix test
mix precommit
```

`mix precommit` runs compile checks, formatting, and tests.

## Authentication and Routes

### Public / current-user routes

- `/` marketing/home page
- `/users/register`
- `/users/log-in`
- `/users/log-in/:token`

### Authenticated routes

- `/dashboard`
- `/organizations`, `/organizations/:id`
- `/projects`, `/projects/:id`
- `/issues`, `/issues/:id`
- `/teams`, `/teams/:id`
- `/users/settings`

These run inside the authenticated LiveView session and require login.

## Email Configuration

FixIt uses Swoosh for email. In development, local mailbox preview is available at `/dev/mailbox` when using the local adapter.

### Gmail SMTP

Set these environment variables to enable Gmail sending:

```bash
export GMAIL_SMTP_USERNAME="your-account@gmail.com"
export GMAIL_SMTP_PASSWORD="your-gmail-app-password"
export GMAIL_SMTP_PORT="587"
export MAIL_FROM_NAME="Fixit"
export MAIL_FROM_EMAIL="your-account@gmail.com"
```

Notes:

- `GMAIL_SMTP_PASSWORD` must be a Gmail App Password, not your normal password.
- If `GMAIL_SMTP_USERNAME` or `GMAIL_SMTP_PASSWORD` are missing, FixIt uses the local mail adapter.

## Runtime Environment Variables

### Required in production

- `DATABASE_PATH`
- `SECRET_KEY_BASE`
- `PHX_HOST` (recommended)
- `PORT` (optional, defaults to `4000`)
- `POOL_SIZE` (optional, defaults to `5`)
- `PHX_SERVER=true` (when running release server process)

### Optional

- `DNS_CLUSTER_QUERY`
- Gmail and mail sender variables above

## Product Context

See [`docs/project_prd_and_workflow.md`](docs/project_prd_and_workflow.md) for:

- Product goals and non-goals
- End-to-end user workflow
- Collaboration and incident lifecycle
- Delivery phases and roadmap

## Deployment

Phoenix deployment documentation:

- https://hexdocs.pm/phoenix/deployment.html
