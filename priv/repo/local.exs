# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     TdAuth.Repo.insert!(%TdAuth.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
alias TdAuth.Accounts.User
alias TdAuth.Repo

Repo.insert!(%User{
  user_name: "user3",
  password: "user3",
  email: "user3@bluetab.net",
  full_name: "User 3",
  is_admin: false,
  is_protected: false
}) # id 3

Repo.insert!(%User{
  user_name: "user",
  password: "user4",
  email: "user4@bluetab.net",
  full_name: "User 4",
  is_admin: false,
  is_protected: false
}) # id 4

Repo.insert!(%User{
  user_name: "user4",
  password: "user4",
  email: "user4@bluetab.net",
  full_name: "User 4",
  is_admin: false,
  is_protected: false
}) # id 5
