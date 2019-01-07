# Changelog

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