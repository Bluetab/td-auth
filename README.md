# TdAuth

## Environment variables

### General

- `TD_AUTH_ALLOW_PROXY_LOGIN` (Optional) Boolean value to allow proxy login. Default: `false`

### Database

- `DB_USER` (Required) Database username
- `DB_PASSWORD` (Required) Database password
- `DB_NAME` (Required) Database name
- `DB_HOST` (Required) Database hostname
- `DB_PORT` (Optional) Database port. Default: `5432`
- `DB_POOL_SIZE` (Optional) Database connection pool size. Default: `4`
- `DB_TIMEOUT_MILLIS` (Optional) Database timeout in milliseconds. Default: `15000`
- `DB_SSL` (Optional) Boolean value to enable SSL configuration. Default: `false`
- `DB_SSL_CACERTFILE` (Optional) Path to the Certification Authority (CA) certificate file, e.g. `/path/to/ca.crt`
- `DB_SSL_VERSION` (Optional) Supported versions are `tlsv1.2` and `tlsv1.3`. Default: `tlsv1.2`
- `DB_SSL_CLIENT_CERT` (Optional) Path to the client SSL certificate file
- `DB_SSL_CLIENT_KEY` (Optional) Path to the client SSL private key file
- `DB_SSL_VERIFY` (Optional) Specifies whether server certificates should be verified. Default: `verify_none`

### Tokens

- `GUARDIAN_SECRET_KEY` (Required) Secret key for JWT token signing
- `ACCESS_TOKEN_TTL_SECONDS` (Optional) Access token time to live in seconds. Default: `600`
- `REFRESH_TOKEN_TTL_SECONDS` (Optional) Refresh token time to live in seconds. Default: `86400`

### Auth0

- `AUTH0_PROTOCOL` (Optional) Auth0 protocol
- `AUTH0_DOMAIN` (Optional) Auth0 domain
- `AUTH0_CLIENT_ID` (Optional) Auth0 client ID
- `AUTH0_AUDIENCE` (Optional) Auth0 audience
- `AUTH0_REDIRECT_URI` (Optional) Auth0 redirect URI
- `AUTH0_SCOPE` (Optional) Auth0 scope
- `AUTH0_CONNECTION` (Optional) Auth0 connection

### LDAP

- `LDAP_SERVER` (Optional) LDAP server hostname
- `LDAP_BASE` (Optional) LDAP base DN
- `LDAP_PORT` (Optional) LDAP port
- `LDAP_SSL` (Optional) LDAP SSL configuration
- `LDAP_USER_DN` (Optional) LDAP user DN
- `LDAP_PASSWORD` (Optional) LDAP password
- `LDAP_CONNECTION_TIMEOUT` (Optional) LDAP connection timeout
- `LDAP_BIND_PATTERN` (Optional) LDAP bind pattern
- `LDAP_SEARCH_PATH` (Optional) LDAP search path
- `LDAP_SEARCH_FIELD` (Optional) LDAP search field
- `LDAP_ATTR_VALIDATIONS_FILE` (Optional) Path to LDAP attribute validations file
- `LDAP_MAPPING_USER_NAME` (Optional) LDAP mapping for user name. Default: `cn`
- `LDAP_MAPPING_FULL_NAME` (Optional) LDAP mapping for full name. Default: `givenName`
- `LDAP_MAPPING_EMAIL` (Optional) LDAP mapping for email. Default: `mail`
- `LDAP_CREATE_GROUP` (Optional) Set to `true` to enable the creation of LDAP-based groups. Default: `false`
- `LDAP_GROUP_FIELDS` (Optional) Comma-separated list of fields used to search for groups to assign to a user
- `LDAP_ALLOWED_GROUPS` (Optional) Comma-separated list of values used to create groups if they are found

### Active Directory (AD)

- `AD_SERVER` (Optional) Active Directory server hostname
- `AD_BASE` (Optional) Active Directory base DN
- `AD_PORT` (Optional) Active Directory port
- `AD_SSL` (Optional) Active Directory SSL configuration
- `AD_USER_DN` (Optional) Active Directory user DN
- `AD_PASSWORD` (Optional) Active Directory password
- `AD_CONNECTION_TIMEOUT` (Optional) Active Directory connection timeout
- `AD_SEARCH_PATH` (Optional) Active Directory search path
- `AD_CERT_PEM_FILE` (Optional) Path to Active Directory certificate PEM file

### OIDC (OpenID Connect)

- `OIDC_DISCOVERY_URI` (Optional) OIDC discovery document URI
- `OIDC_CLIENT_ID` (Optional) OIDC client ID
- `OIDC_CLIENT_SECRET` (Optional) OIDC client secret
- `OIDC_REDIRECT_URI` (Optional) OIDC redirect URI
- `OIDC_SCOPE` (Optional) OIDC scope
- `OIDC_RESPONSE_TYPE` (Optional) OIDC response type. Default: `id_token`
- `OIDC_PROFILE_MAPPING` (Optional) OIDC profile mapping configuration
- `PKCE_CODE_CHALLENGE_METHOD` (Optional) PKCE code challenge method
- `PKCE_CODE_VERIFIER_LENGTH` (Optional) PKCE code verifier length. Default: `128`
- `OIDC_CREATE_GROUP` (Optional) Set to `true` to enable the creation of OIDC-based groups. Default: `false`
- `OIDC_GROUP_FIELDS` (Optional) Comma-separated list of fields used to search for groups to assign to a user
- `OIDC_ALLOWED_GROUPS` (Optional) Comma-separated list of regex patterns used to create groups
  - For example: `^GROUP` would allow all strings that start with "GROUP"
  - If this variable is not set, all values will be accepted

### SAML

- `SAML_CONTACT_EMAIL` (Optional) SAML contact email
- `SAML_CONTACT_NAME` (Optional) SAML contact name
- `SAML_IDP_METADATA_URL` (Optional) SAML Identity Provider metadata URL
- `SAML_ORG_DISPLAY_NAME` (Optional) SAML organization display name
- `SAML_ORG_NAME` (Optional) SAML organization name
- `SAML_ORG_URL` (Optional) SAML organization URL
- `SAML_SP_CERT` (Optional) SAML Service Provider certificate
- `SAML_CONSUME_URI` (Optional) SAML consume URI
- `SAML_SP_ID` (Optional) SAML Service Provider ID
- `SAML_IDP_SIGNS_ENVELOPES` (Optional) Whether the Identity Provider signs envelopes
- `SAML_SP_KEY` (Optional) SAML Service Provider key
- `SAML_METADATA_URI` (Optional) SAML metadata URI
- `SAML_TRUSTED_FINGERPRINTS` (Optional) SAML trusted fingerprints
- `SAML_REJECT_ROLES` (Optional) SAML roles to reject
- `SAML_ALLOW_GROUPS` (Optional) SAML groups to allow
- `SAML_CREATE_GROUP` (Optional) Set to `true` to enable the creation of SAML-based groups. Default: `false`

### Redis

- `REDIS_HOST` (Required) Redis hostname
- `REDIS_PORT` (Optional) Redis port. Default: `6379`
- `REDIS_PASSWORD` (Optional) Redis password
- `REDIS_AUDIT_STREAM_MAXLEN` (Optional) Maximum length for Redis audit stream. Default: `100`
- `REDIS_STREAM_MAXLEN` (Optional) Maximum length for Redis stream. Default: `100`

### HTTP Client

- `PROXY_HOST` (Optional) Proxy hostname
- `PROXY_PORT` (Optional) Proxy port. Default: `80`
- `PROXY_USER` (Optional) Proxy username
- `PROXY_PASSWORD` (Optional) Proxy password
- `CACERTFILE` (Optional) Path to CA certificate file for HTTP client
- `HTTP_SSL_VERIFY` (Optional) HTTP SSL verification mode. Can be `verify_none` or `verify_peer`
- `HTTP_SSL_CACERTFILE` (Optional) Path to CA certificate file when `HTTP_SSL_VERIFY` is set to `verify_peer`
- `HTTP_URL_PREFIX` (Optional) HTTP URL prefix

### Scheduler

- `ACL_LOADER_SCHEDULE` (Optional) Schedule for ACL loader job (cron format). Default: `@reboot`
- `ACL_REMOVER_SCHEDULE` (Optional) Schedule for ACL remover job (cron format). Default: `@hourly`
- `ROLE_LOADER_SCHEDULE` (Optional) Schedule for role loader job (cron format). Default: `@reboot`

To start your Phoenix server:

- Install dependencies with `mix deps.get`
- Create and migrate your database with `mix ecto.create && mix ecto.migrate`
- Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4001`](http://localhost:4001) from your browser.

Ready to run in production? Please [check our deployment guides](http://www.phoenixframework.org/docs/deployment).

## Overview

TdAuth is a back-end service developed as part of True Dat project to manage users and application authentication

## Features

- API Rest interface
- User management
- Session management

## License

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

In order to use this software, it is necessary that, depending on the type of functionality that you want to obtain, it is assembled with other software whose license may be governed by other terms different than the GNU General Public License version 3 or later. In that case, it will be absolutely necessary that, in order to make a correct use of the software to be assembled, you give compliance with the rules of the concrete license (of Free Software or Open Source Software) of use in each case, as well as, where appropriate, obtaining of the permits that are necessary for these appropriate purposes.

## Credits

- Web framework by [Phoenix Community](http://www.phoenixframework.org/)
- Distributed PubSub and Presence platform for the Phoenix Framework by [Phoenix Community](http://www.phoenixframework.org/)
- Phoenix and Ecto integration by [Phoenix Community](http://www.phoenixframework.org/)
- PostgreSQL driver for Elixir by [elixir-ecto Community](http://hexdocs.pm/postgrex/)
- HTTP server for Erlang/OTP by [Nine Nines](https://ninenines.eu)
- Static code analysis tool for the Elixir language by [René Föhring](http://credo-ci.org/)
- Authentication library by [ueberauth](http://blog.overstuffedgorilla.com/)
- Password hashing library by [David Whitlock](https://hex.pm/packages/comeonin)
- Bcrypt password hashing algorithm for Elixir by [David Whitlock](https://github.com/riverrun/bcrypt_elixir)
- Create test data for Elixir applications by [thoughtbot, inc](https://hex.pm/packages/ex_machina)
- Elixir Plug to add CORS by [Michael Schaefermeyer](https://hex.pm/packages/cors_plug)
- HTTP client for Elixir by [Eduardo Gurgel Pinho](https://hex.pm/packages/httpoison)
- Story BDD tool by [Matt Widmann](https://github.com/cabbage-ex/cabbage)
