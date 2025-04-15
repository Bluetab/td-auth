# TdAuth

## Environment variables

### SSL Connection

- `DB_SSL`: Boolean value to enable SSL configuration. Default is `false`.
- `DB_SSL_CACERTFILE`: Path to the Certification Authority (CA) certificate file, e.g. `/path/to/ca.crt`.
- `DB_SSL_VERSION`: Supported versions are `tlsv1.2` and `tlsv1.3`. Default is `tlsv1.2`.
- `DB_SSL_CLIENT_CERT`: Path to the client SSL certificate file.
- `DB_SSL_CLIENT_KEY`: Path to the client SSL private key file.
- `DB_SSL_VERIFY`: Specifies whether server certificates should be verified (`true`/`false`).

### LDAP groups creation

- LDAP_CREATE_GROUP: Set to true to enable the creation of LDAP-based groups.
- LDAP_GROUP_FIELDS: Comma-separated list of fields used to search for groups to assign to a user.
- LDAP_ALLOWED_GROUPS: Comma-separated list of values used to create groups if they are found.

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
