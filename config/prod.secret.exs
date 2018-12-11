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
  # optional
  allowed_algos: ["HS512"],
  issuer: "tdauth",
  token_ttl: %{"access" => {12, :hours}, "refresh" => {24, :hours}},
  secret_key: "${GUARDIAN_SECRET_KEY}"

config :td_auth, :auth,
  auth_service: TdAuthWeb.ApiServices.HttpAuthService,
  protocol: "https",
  domain: "${AUTH_DOMAIN}",
  clientID: "${AUTH_CLIENT_ID}",
  audience: "${AUTH_AUDIENCE}",
  userinfo: "/userinfo",
  profile_mapping: %{user_name: "nickname", full_name: ["name", "family_name"], email: "email"}

config :td_auth, TdAuth.Auth.Auth,
  allowed_algos: ["RS256"],
  issuer: "${AUTH_ISSUER}",
  verify_issuer: true,
  secret_key: AUTH0_SECRET_KEY

config :td_auth, :ldap,
  server: "${LDAP_SERVER}",
  base: "${LDAP_BASE}",
  port: "${LDAP_PORT}",
  ssl: "${LDAP_SSL}",
  user_dn: "${LDAP_USER_DN}",
  password: "${LDAP_PASSWORD}",
  connection_timeout: "${LDAP_CONNECTION_TIMEOUT}",
  profile_mapping: "{\"user_name\":\"cn\",\"full_name\":\"cn\",\"email\":\"cn\"}",
  # profile_mapping: "${LDAP_PROFILE_MAPPING}",
  bind_pattern: "${LDAP_BIND_PATTERN}",
  search_path: "${LDAP_SEARCH_PATH}",
  search_field: "${LDAP_SEARCH_FIELD}"

config :td_auth, :ad,
  server: "${AD_SERVER}",
  base: "${AD_BASE}",
  port: "${AD_PORT}",
  ssl: "${AD_SSL}",
  user_dn: "${AD_USER_DN}",
  password: "${AD_PASSWORD}",
  connection_timeout: "${AD_CONNECTION_TIMEOUT}",
  search_path: "${AD_SEARCH_PATH}"

config :td_auth, :openid_connect_providers,
  oidc: [
    discovery_document_uri: "${OIDC_DISCOVERY_URI}",
    client_id: "${OIDC_CLIENT_ID}",
    client_secret: "${OIDC_CLIENT_SECRET}",
    redirect_uri: "${OIDC_REDIRECT_URI}",
    scope: "${OIDC_SCOPE}"
  ]

config :td_perms, redis_host: "${REDIS_HOST}"
