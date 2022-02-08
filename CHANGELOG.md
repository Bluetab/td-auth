# Changelog

## [4.32.0] 2021-11-15

### Added

- [TD-4456] Include user external_id in UserCache.put
- [TD-4228] Include optional `external_id` for users

## [4.31.0] 2021-11-02

### Changed

- [TD-4203] Update `td-cache` for role permissions

## [4.29.2] 2021-10-07

### Fixed

- [TD-4205] TdAuth.Permissions.RoleLoader server was not started on application

## [4.29.1] 2021-10-07

### Fixed

- [TD-4044] Filter permissions without role before putting to cache

## [4.29.0] 2021-10-04

### Added

- [TD-4057] OIDC: Allow discovery uri to be self-signed
- New permission `approve_grant_request`
- [TD-4076] store roles with permissions in cache

## [4.26.1] 2021-08-18

### Fixed

- [TD-4030] Conflict with permission `create_grant_request`

## [4.26.0] 2021-08-16

### Added

- [TD-3931] Update acl entry resource
- [TD-3982] New permission `create_grant_request`

## [4.25.0] 2021-07-26

### Fixed

- [TD-3833] Allow to setup user groups to be allowed to enter the application
  for SAML integration

### Added

- [TD-3945] New permissions to view and manage grants
- [TD-3947] Updated td-cache to write cache for user_name
- [TD-3873] Include a specific permission to be able to share a concept with a
  domain

## [4.24.0] 2021-07-13

### Added

- [TD-3833] Allow to setup user groups to be allowed to enter the application
  for SAML integration

### Changed

- [TD-3894] User email is now optional
- Removed deprecated `is_admin` field in user requests and responses

### Added

- [TD-3617] url in state for auth0 and idc

## [4.23.0] 2021-06-28

### Added

- [TD-3720] New permission `manage_structures_domain`
- [TD-3900] Allow proxy authentication in `OpenIdConnect`

### Changed

- [TD-3522] Added permissions to StructureNotes management

## [4.21.1] 2021-06-03

### Changed

- [TD-3816] Build using Elixir 1.12 and Erlang/OTP 23

## [4.21.0] 2021-05-31

### Changed

- [TD-3102] Improve change password functionality
- [TD-3753] Build using Elixir 1.12 and Erlang/OTP 24

### Added

- [TD-3503]
  - Created APIs `api/users/search` and `api/groups/search`
  - Removed permissions for non-admin users to `:index` users and groups

## [4.20.0] 2021-05-17

### Added

- [TD-3526] `link_data_structure_tag` permission to link a structure to a tag

## [4.19.0] 2021-05-04

### Added

- [TD-3628] Force release to update base image

## [4.17.0] 2021-04-05

### Changed

- [TD-3445] Postgres port configurable through `DB_PORT` environment variable

## [4.16.0] 2021-03-22

### Changed

- [TD-3326] Configure JWT token TTL using environment variables
- [TD-3297] PKCE code verifier length is now configurable using environment
  variable `PKCE_CODE_VERIFIER_LENGTH` (defaults to 128)

### Added

- [TD-1389] Generates events for login attempts and successes

### Added

- [TD-2951] Permission `profile_structures`.

## [4.15.0] 2021-03-08

### Changed

- Build with `elixir:1.11.3-alpine`, runtime `alpine:3.13`

## [4.14.0] 2021-02-22

### Changed

- [TD-3245] Tested compatibility with PostgreSQL 9.6, 10.15, 11.10, 12.5 and
  13.1. CI pipeline changed to use `postgres:12.5-alpine`.

### Added

- [TD-3296] Support for PKCE in OAuth 2.0 authentication code flow. To enable
  PKCE, set the environment varible `PKCE_CODE_CHALLENGE_METHOD` to `S256`.

## [4.13.0] 2021-02-08

### Changed

- [TD-3146] Delete acl entries from deleted domain ids collection

## [4.12.0] 2021-01-25

### Added

- [TD-3163] Initial support for service accounts
- [TD-3164] Service accounts can view auth API resources

### Changed

- [TD-3163] Auth tokens now include rule claim instead of is_admin flag
- [TD-3182] Allow to use redis with password
- [TD-3074] Allow to query `users` and `groups` for users having permissions in
  bg

### Deleted

- [TD-3162] users `is_protected` field

## [4.11.0] 2021-01-11

### Changed

- [TD-3170] Build docker image which runs with non-root user
- [TD-3139] `/api/init` now creates the initial admin user as unprotected unless
  `is_protected: true` is specified in the payload

## [4.10.0] 2020-12-14

### Added

- [TD-3143] Support Azure Active Directory with OAuth 2.0 auth code flow
- [TD-2486] Permissions `manage_data_sources` and `manage_configurations`

### Changed

- [TD-2461] Split `business_glossary` permission group into groups
  `business_glossary_view` and `business_glossary_management`

## [4.9.0] 2020-11-30

### Changed

- [TD-3101] `GET /api/users/init/can` Verifies if unprotected users exists

## [4.8.0] 2020-11-16

### Fixed

- [TD-3110] Increased maximum accepted length of HTTP request header values

## [4.7.0] 2020-11-03

### Changed

- [TD-3047] Renamed permission `execute_quality_rule` to
  `execute_quality_rule_implementations`

## [4.3.0] 2020-09-07

### Added

- [TD-2872] `GET /api/users/init/can` Can create initial user

## [4.2.0] 2020-08-17

### Fixed

- [TD-2534] Refresh acl cache after group is updated

### Changed

- [TD-2280] Do not reference to domains by their names

## [4.0.0] 2020-07-01

### Changed

- [TD-2687] Remove `email` and `is_admin` from principal in ACL entry responses
- [TD-2684] `POST /api/:resource_type/:resource_id/acl_entries` to create a new
  ACL entry for a resource
- Updated to Phoenix 1.5

### Removed

- [TD-2684] `PATCH /api/:resource_type/:resource_id/acl_entries` is no longer
  used, removed unused `update_acl_entry` permission check
- Prometheus metrics exporter

## [3.20.0] 2020-04-20

### Added

- [TD-2361] Manage raw rule implementations permission

## [3.19.0] 2020-04-06

### Added

- [TD-2394] Endpoint for returning user permissions domains

### Changed

- [TD-940] Migrated to Elixir 1.10, simplified routes, improved hypermedia on
  `/api/:resource_type/:resource_id/acl_entries`

## [3.18.0] 2020-03-23

### Added

- [TD-2281] Include permission groups in JWT token, added permissions for
  dashboards and lineage

## [3.15.0] 2020-02-10

### Added

- [TD-2330] Allow custom login validations based on Ldap attributes
- [TD-832] Group api for permissions

## [3.11.0] 2019-11-25

### Changed

- Default log format is now with UTC timestamp and includes PID and module
  metadata

## [3.9.0] 2019-10-29

### Added

- [TD-2170] permission to manage metadata

## [3.8.0] 2019-10-14

### Changed

- [TD-2181] Proxy login now returns token on first step

## [3.7.0] 2019-09-30

### Changed

- Use td-cache 3.7.0

## [3.6.0] 2019-09-16

### Added

- [TD-740] Group users endpoint

### Changed

- Use td-cache 3.5.1
- Use td-hypermedia 3.6.1

## [3.4.0] 2019-08-19

### Added

- [TD-2044] Permission execute_quality_rule

## [3.3.0] 2019-08-05

### Added

- [TD-1775] Permission manage quality rule implementations
- [TD-1776] Permission view_quality_rule

## [3.2.0] 2019-07-24

### Changed

- [TD-2002] Update td-cache and delete permissions list from config

## [3.1.0] 2019-07-08

### Changed

- [TD-1594] fix allow_proxy_login config to accept environment value
- [TD-1618] Cache improvements (use td-cache instead of td-perms)

## [3.0.0] 2019-06-25

### Added

- [TD-1594] Support for proxy login
- [TD-1893] Use CI_JOB_ID instead of CI_PIPELINE_ID

## [2.21.0] 2019-06-10

### Added

- [TD-1702] New permission view_data_structures_profile

### Changed

- [TD-1699] New flow for ldap authentication

## [2.20.0] 2019-05-27

### Added

- [TD-1535] New permission manage_ingest_relations

## [2.19.0] 2019-05-14

### Fixed

- [TD-1774] Newline is missing in logger format

## [2.18.0] 2019-04-23

### Changed

- [TD-1605] Remove acl entry from cache at delete

## [2.17.0] 2019-04-17

### Changed

- [TD-1636] Use alpine:3.9 as base image for docker runtime

## [2.16.0] 2019-04-01

### Added

- [TD-1544] Added a connection parameter to Auth0 config
- [TD-1571] Elixir's Logger config will check for EX_LOGGER_FORMAT variable to
  override format

## [2.14.0] 2019-03-04

### Changed

- [TD-1463] Added a description field to acl_entries
- [TD-1463] Description field has now 120 charactes length

## [2.13.0] 2019-02-11

### Changed

- [TD-1087] control role name uniqueness on changeset

## [2.12.5] 2019-01-31

### Changed

- Updated esaml to v4.1.0

## [2.12.4] 2019-01-30

### Changed

- Removed access_method variable from session create

## [2.12.3] 2019-01-28

### Added

- [TD-980] An user can change his password if he is logged with username and
  password

## [2.12.2] 2019-01-25

### Changed

- `/api/init` is now a POST method allowing initial credentials to be specified
- Improve naming of Auth0 configuration variables

## [2.12.0] 2019-01-24

### Changed

- [TD-1379] SAML authentication: allow certain roles to be rejected

## [2.11.12] 2019-01-23

### Fixed

- Variable Auth0 Configuration

## [2.11.11] 2019-01-17

### Changed

- [TD-1326] include SAML name attribute in profile mapping

## [2.11.10] 2019-01-16

### Changed

- rename init endpoint to api/init

## [2.11.8] 2019-01-15

### Changed

- [TD-1357] removed default users from migration and added init_credential
  endpoint

## [2.11.7] 2019-01-15

### Changed

- [TD-1326] support for SAML authentication flow

## [2.11.3] 2019-01-07

### Changed

- CI builds are now on OTP 21.2 and Elixir 1.7.4
- Update to distillery 2.0
- Removed unused edeliver artifacts

## [2.11.0] 2019-01-05

### Fixed

- Response codes 403 (forbidden) and 401 (unauthorized) were sometimes being
  used incorrectly

### Changed

- Update to phoenix 1.4.0, ecto 3.0
- Remove unused channels / phoenix_pubsub artifacts

## [2.10.3] 2018-12-18

### Added

- Added manage_confidential_structures permission
- Update td_perms version 2.10.0

## [2.10.2] 2018-12-17

### Changed

- Update to openid_connect 0.2.0 and specify id_token as resposne type

## [2.10.1] 2018-12-12

### Changed

- [TD-1172] Fixed missing authorization for update_acl_entry

## [2.10.0] 2018-12-11

### Changed

- [TD-1153] Refactor /api/auth :index. Now it returns a map with the various
  available auth methods configurated
- Production build requires new environment variable: AUTH_CLIENT_ID

## [2.8.2] 2018-11-25

### Added

- Get surname in login with Auth0

## [2.8.1] 2018-11-15

### Changed

- Update dependencies (td-perms 0.8.2, credo 0.10.2)
- Configurable log level for controllers and reduce logging in PingController

## [2.7.8] 2018-11-12

### Added

- User cache loader writes user email by full_name

## [2.7.7] 2018-11-08

### Added

- API endpoint to list authentication methods (currently only returns OIDC
  endpoint)

## [2.7.6] 2018-11-08

### Fixed

- Prevent application startup from failing if OIDC environment variables are
  absent

## [2.7.5] 2018-10-31

### Fixed

- Failure loading acl cache when user list is empty

## [2.7.2] 2018-10-31

### Added

- Support for OpenID Connect
