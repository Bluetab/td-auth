#!/bin/bash

cp -R /code /working_code
chmod -R 777 /working_code
cd /working_code

mix release --env=prod
yes | cp _build/dev/rel/td_auth/releases/0.0.1/td_auth.tar.gz /code/dist/
