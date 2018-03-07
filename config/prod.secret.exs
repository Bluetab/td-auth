use Mix.Config

# In this file, we keep production configuration that
# you'll likely want to automate and keep away from
# your version control system.
#
# You should document the content of this
# file or create a script for recreating it, since it's
# kept out of version control and might be hard to recover
# or recreate for your teammates (or yourself later on).
config :td_auth, TdAuthWeb.Endpoint,
  secret_key_base: "fZFsyAqGLetD8LXb4tbkrHT04TLU8RaNaYyTOZOlw95hybq9zbGsAGsNlLOqlb0+"

# Configure your database
config :td_auth, TdAuth.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "td_auth_prod",
  hostname: "localhost",
  pool_size: 10

config :td_auth, TdAuth.Auth.Guardian,
  allowed_algos: ["HS512"], # optional
  issuer: "tdauth",
  ttl: { 1, :hours },
  secret_key: "SuperSecretTruedat"
