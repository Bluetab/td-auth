# Changelog

## [Unreleased] 

### Changed

- [TD-2002] Update td-cache and delete permissions list from config
- [TD-1776] add permission view_quality_rule

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
- [TD-1571] Elixir's Logger config will check for EX_LOGGER_FORMAT variable to override format

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

- [TD-980] An user can change his password if he is logged with username and password

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

- [TD-1357] removed default users from migration and added init_credential endpoint

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

- Response codes 403 (forbidden) and 401 (unauthorized) were sometimes being used incorrectly

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

- [TD-1153] Refactor /api/auth :index. Now it returns a map with the various available auth methods configurated
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

- API endpoint to list authentication methods (currently only returns OIDC endpoint)

## [2.7.6] 2018-11-08

### Fixed

- Prevent application startup from failing if OIDC environment variables are absent

## [2.7.5] 2018-10-31

### Fixed

- Failure loading acl cache when user list is empty

## [2.7.2] 2018-10-31

### Added

- Support for OpenID Connect
