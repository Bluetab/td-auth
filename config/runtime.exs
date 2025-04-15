import Config

config :td_auth, allow_proxy_login: System.get_env("TD_AUTH_ALLOW_PROXY_LOGIN", "false")

config :td_cluster, groups: [:auth]

# Configure your database
if config_env() == :prod do
  get_ssl_option = fn env_var, option_key ->
    if System.get_env("DB_SSL", "") |> String.downcase() == "true" do
      case System.get_env(env_var, "") do
        "" -> []
        "nil" -> []
        value -> [{option_key, value}]
      end
    else
      []
    end
  end

  optional_db_ssl_options_cacertfile = get_ssl_option.("DB_SSL_CACERTFILE", :cacertfile)
  optional_db_ssl_options_certfile = get_ssl_option.("DB_SSL_CLIENT_CERT", :certfile)
  optional_db_ssl_options_keyfile = get_ssl_option.("DB_SSL_CLIENT_KEY", :keyfile)

  config :td_auth, TdAuth.Repo,
    username: System.fetch_env!("DB_USER"),
    password: System.fetch_env!("DB_PASSWORD"),
    database: System.fetch_env!("DB_NAME"),
    hostname: System.fetch_env!("DB_HOST"),
    port: System.get_env("DB_PORT", "5432") |> String.to_integer(),
    pool_size: System.get_env("DB_POOL_SIZE", "4") |> String.to_integer(),
    timeout: System.get_env("DB_TIMEOUT_MILLIS", "15000") |> String.to_integer(),
    ssl: System.get_env("DB_SSL", "") |> String.downcase() == "true",
    ssl_opts:
      [
        verify:
          System.get_env("DB_SSL_VERIFY", "verify_none") |> String.downcase() |> String.to_atom(),
        server_name_indication: System.get_env("DB_HOST") |> to_charlist(),
        versions: [
          System.get_env("DB_SSL_VERSION", "tlsv1.2") |> String.downcase() |> String.to_atom()
        ]
      ] ++
        optional_db_ssl_options_cacertfile ++
        optional_db_ssl_options_certfile ++
        optional_db_ssl_options_keyfile

  config :joken,
    default_signer: [
      signer_alg: "HS512",
      key_octet: System.fetch_env!("GUARDIAN_SECRET_KEY")
    ]

  config :td_auth, TdAuth.Auth.AccessToken,
    ttl_seconds: System.get_env("ACCESS_TOKEN_TTL_SECONDS", "600") |> String.to_integer()

  config :td_auth, TdAuth.Auth.RefreshToken,
    ttl_seconds: System.get_env("REFRESH_TOKEN_TTL_SECONDS", "86400") |> String.to_integer()

  config :td_auth, :auth0,
    protocol: System.get_env("AUTH0_PROTOCOL"),
    domain: System.get_env("AUTH0_DOMAIN"),
    client_id: System.get_env("AUTH0_CLIENT_ID"),
    audience: System.get_env("AUTH0_AUDIENCE"),
    redirect_uri: System.get_env("AUTH0_REDIRECT_URI"),
    scope: System.get_env("AUTH0_SCOPE"),
    response_type: "token id_token",
    userinfo: "/userinfo",
    connection: System.get_env("AUTH0_CONNECTION")

  config :td_auth, :ldap,
    server: System.get_env("LDAP_SERVER"),
    base: System.get_env("LDAP_BASE"),
    port: System.get_env("LDAP_PORT"),
    ssl: System.get_env("LDAP_SSL"),
    user_dn: System.get_env("LDAP_USER_DN"),
    password: System.get_env("LDAP_PASSWORD"),
    connection_timeout: System.get_env("LDAP_CONNECTION_TIMEOUT"),
    bind_pattern: System.get_env("LDAP_BIND_PATTERN"),
    search_path: System.get_env("LDAP_SEARCH_PATH"),
    search_field: System.get_env("LDAP_SEARCH_FIELD"),
    validations_file: System.get_env("LDAP_ATTR_VALIDATIONS_FILE"),
    profile_mapping: %{
      user_name: System.get_env("LDAP_MAPPING_USER_NAME", "cn"),
      full_name: System.get_env("LDAP_MAPPING_FULL_NAME", "givenName"),
      email: System.get_env("LDAP_MAPPING_EMAIL", "mail")
    },
    create_groups: System.get_env("LDAP_CREATE_GROUP", "false") |> String.downcase() == "true",
    group_fields:
      System.get_env("LDAP_GROUP_FIELDS", "")
      |> String.split(",", trim: true),
    allowed_groups:
      System.get_env("LDAP_ALLOWED_GROUPS", "")
      |> String.split(",", trim: true)

  config :td_auth, :ad,
    server: System.get_env("AD_SERVER"),
    base: System.get_env("AD_BASE"),
    port: System.get_env("AD_PORT"),
    ssl: System.get_env("AD_SSL"),
    user_dn: System.get_env("AD_USER_DN"),
    password: System.get_env("AD_PASSWORD"),
    connection_timeout: System.get_env("AD_CONNECTION_TIMEOUT"),
    search_path: System.get_env("AD_SEARCH_PATH"),
    sslopts: [cacertfile: System.get_env("AD_CERT_PEM_FILE"), verify: :verify_peer]

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
    reject_roles: System.get_env("SAML_REJECT_ROLES"),
    allow_groups: System.get_env("SAML_ALLOW_GROUPS"),
    create_group: System.get_env("SAML_CREATE_GROUP", "false")

  config :td_cache,
    redis_host: System.fetch_env!("REDIS_HOST"),
    port: System.get_env("REDIS_PORT", "6379") |> String.to_integer(),
    password: System.get_env("REDIS_PASSWORD")

  config :td_auth, TdAuthWeb.AuthProvider.OIDC,
    profile_mapping: System.get_env("OIDC_PROFILE_MAPPING"),
    code_challenge_method: System.get_env("PKCE_CODE_CHALLENGE_METHOD"),
    code_verifier_length:
      System.get_env("PKCE_CODE_VERIFIER_LENGTH", "128") |> String.to_integer()

  config :td_auth, TdAuth.HttpClient,
    proxy:
      {System.get_env("PROXY_HOST"), System.get_env("PROXY_PORT", "80") |> String.to_integer()},
    proxy_auth: {System.get_env("PROXY_USER"), System.get_env("PROXY_PASSWORD")},
    hackney: [
      ssl_options: [
        cacertfile: System.get_env("CACERTFILE")
      ]
    ]

  config :td_auth, TdAuth.Scheduler,
    jobs: [
      [
        schedule: System.get_env("ACL_LOADER_SCHEDULE", "@reboot"),
        task: {TdAuth.Permissions.AclLoader, :load_cache, []},
        run_strategy: Quantum.RunStrategy.Local
      ],
      [
        schedule: System.get_env("ACL_REMOVER_SCHEDULE", "@hourly"),
        task: {TdAuth.Permissions.AclRemover, :delete_stale_acl_entries, []},
        run_strategy: Quantum.RunStrategy.Local
      ],
      [
        schedule: System.get_env("ROLE_LOADER_SCHEDULE", "@reboot"),
        task: {TdAuth.Permissions.RoleLoader, :load_roles, []},
        run_strategy: Quantum.RunStrategy.Local
      ]
    ]
end
