# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Fixit.Repo.insert!(%Fixit.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Fixit.Accounts
alias Fixit.Accounts.User
alias Fixit.Repo

defmodule Fixit.Seeds do
  def up do
    seed_user(%{
      first_name: "Amina",
      last_name: "Hassan",
      email: "amina@fixit.dev",
      password: "ChangeMe123456!"
    })

    seed_user(%{
      first_name: "Eli",
      last_name: "Morgan",
      email: "eli@fixit.dev",
      password: "ChangeMe123456!"
    })
  end

  defp seed_user(attrs) do
    case Accounts.get_user_by_email(attrs.email) do
      %User{} = user ->
        user

      nil ->
        %User{}
        |> User.registration_changeset(attrs)
        |> Repo.insert!()
        |> User.confirm_changeset()
        |> Repo.update!()
    end
  end
end

Fixit.Seeds.up()
