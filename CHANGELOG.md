# Changelog

## [7.7.0] 2025-06-30

### Added

- [TD-7299] Refactor gitlab-ci pipeline and add Trivy check

## [7.6.0] 2025-06-10

### Added

- [TD-7176] Add Grant Request logic for foreign requests

## [7.5.0] 2025-04-30

### Fixed

-[TD-7226] Enhance SSL configuration handling in production

## [7.4.0] 2025-04-09

### Changed

- License and libraries

## [7.3.0] 2025-03-18

### Changed

- [TD-7126] Enable the creation of LDAP-based groups using params from Distinguished Name.

## [7.1.0] 2025-02-04

### Changed

- [TD-6862] Optimize QX permissions

## [7.0.0] 2025-01-13

### Changed

- [TD-6911]
  - update Elixir 1.18
  - update dependencies
  - update Docker RUNTIME_BASE=alpine:3.21
  - remove unused dependencies
  - remove swagger
  - remove cabagge

## [6.16.0] 2024-12-16

### Added

- [TD-6865] Automatically create groups based on LDAP

### Fixed

- [TD-6989] Roolback 6811 and include profile_mapping configuration in runtime

## [6.15.1] 2024-12-09

### Fixed

- [TD-6991] Put permission roles in cache when roles are edited

## [6.15.0] 2024-11-27

### Added

- [TD-6811] Add uid field to LDAP integration

### Fixed

- [TD-6950] Fix add and delete user role functionality

## [6.12.0] 2024-09-23

### Added

- [TD-6184] Role for Agents, and remove role_type fro users

## [6.9.0] 2024-07-26

### Changed

- [TD-6602] Update cache when ACL resource is created, edited or deleted

## [6.7.0] 2024-06-13

### Fixed

- [TD-6619] Fix pattern matching for empty sslopts

## [6.6.0] 2024-05-22

## [6.5.4] 2024-05-22

### Fixed

- [TD-6619] Add sslopt to exladp.open

## [6.5.3] 2024-05-22

### Fixed

- [TD-6619] Function typo

## [6.5.2] 2024-05-22

### Added

- [TD-6619] Add ad sslops and remove environment variables for booleans

## [6.5.1] 2024-05-22

### Fixed

- [TD-6619] Environment variables for booleans in td-auth

## [6.5.0] 2024-04-30

### Added

- [TD-5520] Added new permissions group to visualize grants

### Fixed

- [TD-5495] Foreing keys columns should match original ID columns in all tables

## [6.4.0] 2024-04-09

### Fixed

- [TD-6386] Users listing with Default Role Permissions

## [6.3.0] 2024-03-18

### Added

- [TD-4110] Allow structure scoped permissions management

## [6.2.0] 2024-02-26

### Fixed

- [TD-6425] Ensure SSL if configured for release migration

## [6.0.0] 2024-01-17

## Added

- [TD-6195] Permissions for Business Concept Ai Suggestions
- [TD-6336] Get test-truedat-eks config on deploy stage

## [5.20.0] 2023-12-19

## Added

- [TD-6152] Permissions for QX executions

## [5.19.0] 2023-11-28

## Added

- [TD-6140] Added permissions for Ai suggestions
- [TD-5505] Added permissions for `manage_grant_removal` and `manage_foreign_grant_removal`

## [5.17.0] 2023-11-02

## Added

- [TD-6059] Added permissions for QualityControls

### Fixed

- [TD-6079] Allow all users to get roles

## [5.12.0] 2023-08-16

## Changed

- [TD-5468] Change the resource_acl_path to acl_path for kong update version

## [5.10.0] 2023-07-06

## Changed

- [TD-5912] `.gitlab-ci.yml` adaptations for develop and main branches

## [5.9.0] 2023-06-20

## Added

- [TD-5770] Add database TSL configuration

## [5.8.0] 2023-06-06

- [TD-5691] Domains and role filter for grant requests

## [5.5.0] 2023-04-18

### Added

- [TD-5297] Added `DB_SSL` environment variable for Database SSL connection

## [5.3.0] 2023-03-13

- [TD-5509] link_structure_to_structure permission

## [4.58.0] 2022-12-27

### Added

- [TD-4300] manage_basic_implementations permission

## [4.56.0] 2022-11-28

### Changed

- [TD-5258] Add `role` to user data
- [TD-5256] Update dependencies, build with `elixir-1.13.4-alpine`

## [4.54.0] 2022-10-31

### Changed

- [TD-5284] Phoenix 1.6.x

## [4.52.0] 2022-10-03

### Added

- [TD-4903] Include `sobelow` static code analysis in CI pipeline

## [4.51.0] 2022-09-19

### Added

- [TD-5082] view_protected_metadata permission
- [TD-5133] filter on /user/search for retreaving users with a specific permission

## [4.50.0] 2022-09-05

### Added

- [TD-5036] Support for custom permissions

## [4.48.0] 2022-07-26

### Changed

- [TD-3614] Support short-lived access tokens with refresh mechanism using
  secure cookie

## [4.47.0] 2022-07-04

### Added

- [TD-4412] Support for caching groups and group related acls

## [4.46.0] 2022-06-20

### Added

- [TD-4431] New permission `request_grant_removal`
- [TD-4918] Refactor quality implementations permissions

## [4.45.0] 2022-06-06

### Added

- [TD-4540] New permissions for implementation workflow

## [4.44.0] 2022-05-23

### Added

- [TD-4089] New permission `manage_ruleless_implementations`

## [4.43.0] 2022-05-09

- [TD-4538] New permission `manage_segments` in `data_quality`

## [4.42.0] 2022-04-25

### Added

- [TD-4271] New permissions `link_implementation_structure`

### Fixed

- [TD-4625] `RoleLoader.load_roles/0` was failing when no roles exist

## [4.40.1] 2022-03-21

### Added

- [TD-4271] New permissions `link_implementation_business_concept`
- [TD-3233] Rule result remediation plan `manage_remediations` permission
- [TD-4577] Move view `StructureNotes` permissions to `data_structure` group

## [4.40.0] 2022-03-14

### Changed

- [TD-2501] Database timeout and pool size can now be configured using
  `DB_TIMEOUT_MILLIS` and `DB_POOL_SIZE` environment variables
- [TD-4491] Caching of permissions has been refactored

### Removed

- [TD-4604] Removed route `/api/users/me/permissions`

## [4.38.0] 2022-02-22

### Added

- New permissions:
  - [TD-4437] `manage_rule_results`
  - [TD-4481] `manage_business_concepts_domain`

## [4.37.0] 2022-02-10

### Added

- [TD-4456] Include user external_id in UserCache.put (**removes [TD-4212]**)

## [4.32.0] 2021-11-15

### Added

- [TD-4228] Include optional `external_id` for users

## [4.31.0] 2021-11-02

### Fixed

- [TD-4212]
  - Remove ACLs after domain member deletion
  - Remove ACLs after user deletion

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
