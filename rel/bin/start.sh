#!/bin/sh

set -o errexit
set -o xtrace

bin/td_auth eval 'Elixir.TdAuth.Release.migrate()'
bin/td_auth start
