defmodule Fixit.Repo do
  use Ecto.Repo,
    otp_app: :fixit,
    adapter: Ecto.Adapters.SQLite3
end
