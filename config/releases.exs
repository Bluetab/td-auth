import Config

# In this file, we keep production configuration that
# you'll likely want to automate and keep away from
# your version control system.
#
# You should document the content of this
# file or create a script for recreating it, since it's
# kept out of version control and might be hard to recover
# or recreate for your teammates (or yourself later on).

config :td_auth, allow_proxy_login: System.get_env("TD_AUTH_ALLOW_PROXY_LOGIN", "false")

# Configure your database
config :td_auth, TdAuth.Repo,
  username: System.fetch_env!("DB_USER"),
  password: System.fetch_env!("DB_PASSWORD"),
  database: System.fetch_env!("DB_NAME"),
  hostname: System.fetch_env!("DB_HOST")

config :td_auth, TdAuth.Auth.Guardian, secret_key: System.fetch_env!("GUARDIAN_SECRET_KEY")

config :td_auth, :auth0,
  protocol: System.get_env("AUTH0_PROTOCOL"),
  domain: System.get_env("AUTH0_DOMAIN"),
  client_id: System.get_env("AUTH0_CLIENT_ID"),
  audience: System.get_env("AUTH0_AUDIENCE"),
  redirect_uri: System.get_env("AUTH0_REDIRECT_URI"),
  scope: System.get_env("AUTH0_SCOPE"),
  response_type: "token id_token",
  userinfo: "/userinfo",
  profile_mapping: %{user_name: "nickname", full_name: ["name", "family_name"], email: "email"},
  connection: System.get_env("AUTH0_CONNECTION")

config :td_auth, :ldap,
  server: System.get_env("LDAP_SERVER"),
  base: System.get_env("LDAP_BASE"),
  port: System.get_env("LDAP_PORT"),
  ssl: System.get_env("LDAP_SSL"),
  user_dn: System.get_env("LDAP_USER_DN"),
  password: System.get_env("LDAP_PASSWORD"),
  connection_timeout: System.get_env("LDAP_CONNECTION_TIMEOUT"),
  profile_mapping: "{\"user_name\":\"cn\",\"full_name\":\"givenName\",\"email\":\"mail\"}",
  # profile_mapping: System.get_env("LDAP_PROFILE_MAPPING"),
  bind_pattern: System.get_env("LDAP_BIND_PATTERN"),
  search_path: System.get_env("LDAP_SEARCH_PATH"),
  search_field: System.get_env("LDAP_SEARCH_FIELD"),
  validations_file: System.get_env("LDAP_ATTR_VALIDATIONS_FILE")

config :td_auth, :ad,
  server: System.get_env("AD_SERVER"),
  base: System.get_env("AD_BASE"),
  port: System.get_env("AD_PORT"),
  ssl: System.get_env("AD_SSL"),
  user_dn: System.get_env("AD_USER_DN"),
  password: System.get_env("AD_PASSWORD"),
  connection_timeout: System.get_env("AD_CONNECTION_TIMEOUT"),
  search_path: System.get_env("AD_SEARCH_PATH")

config :td_auth, :openid_connect_providers,
  oidc: [
    discovery_document_uri: System.get_env("OIDC_DISCOVERY_URI"),
    client_id: System.get_env("OIDC_CLIENT_ID"),
    client_secret: System.get_env("OIDC_CLIENT_SECRET"),
    redirect_uri: System.get_env("OIDC_REDIRECT_URI"),
    scope: System.get_env("OIDC_SCOPE"),
    response_type: System.get_env("OIDC_RESPONSE_TYPE", "id_token")
  ]

config :td_auth, :saml,
  contact_email: System.get_env("SAML_CONTACT_EMAIL"),
  contact_name: System.get_env("SAML_CONTACT_NAME"),
  idp_metadata_url: System.get_env("SAML_IDP_METADATA_URL"),
  org_display_name: System.get_env("SAML_ORG_DISPLAY_NAME"),
  org_name: System.get_env("SAML_ORG_NAME"),
  org_url: System.get_env("SAML_ORG_URL"),
  sp_cert: System.get_env("SAML_SP_CERT"),
  sp_consume_uri: System.get_env("SAML_CONSUME_URI"),
  sp_id: System.get_env("SAML_SP_ID"),
  sp_idp_signs_envelopes: System.get_env("SAML_IDP_SIGNS_ENVELOPES"),
  sp_key: System.get_env("SAML_SP_KEY"),
  sp_metadata_uri: System.get_env("SAML_METADATA_URI"),
  sp_trusted_fingerprints: System.get_env("SAML_TRUSTED_FINGERPRINTS"),
  reject_roles: System.get_env("SAML_REJECT_ROLES")

config :td_cache,
  redis_host: System.fetch_env!("REDIS_HOST"),
  port: System.get_env("REDIS_PORT", "6379") |> String.to_integer(),
  password: System.get_env("REDIS_PASSWORD")

config :td_auth, TdAuthWeb.AuthProvider.OIDC,
  profile_mapping: System.get_env("OIDC_PROFILE_MAPPING"),
  code_challenge_method: System.get_env("PKCE_CODE_CHALLENGE_METHOD")
