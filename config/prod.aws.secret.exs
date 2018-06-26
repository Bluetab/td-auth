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
  username: "${DB_USER}",
  password: "${DB_PASSWORD}",
  database: "${DB_NAME}",
  hostname: "${DB_HOST}",
  pool_size: 10

config :td_auth, TdAuth.Auth.Guardian,
  allowed_algos: ["HS512"], # optional
  issuer: "tdauth",
  token_ttl: %{"access" => { 12, :hours }, "refresh" => {24, :hours}},
  secret_key: "${GUARDIAN_SECRET_KEY}"

config :td_auth, :auth,
  auth_service: TdAuthWeb.ApiServices.HttpAuthService,
  protocol: "https",
  domain: "${AUTH_DOMAIN}",
  audience: "${AUTH_AUDIENCE}",
  userinfo: "/userinfo",
  profile_mapping: %{user_name: "nickname",
                     full_name: "name",
                     email:     "email"}

 config :td_auth, TdAuth.Auth.Auth,
   allowed_algos: ["RS256"],
   issuer: "${AUTH_ISSUER}",
   verify_issuer: true,
   secret_key: "${AUTH_SECRET_KEY}"