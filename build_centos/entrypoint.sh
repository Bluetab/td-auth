#!/bin/bash

cp -R /code /working_code
chmod -R 777 /working_code
cd /working_code

echo "Starting deploy"

MIX_ENV=prod
mix local.rebar --force
rm -rf ./_build
mix deps.clean --all
mix deps.get

mix release --env=prod
cp _build/dev/rel/td_auth/releases/0.0.1/td_auth.tar.gz /code/dist/

echo "Finished deployment"
