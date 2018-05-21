#!/bin/bash
sed -i -e "s/username:.*,/username: \"$DB_USER\",/g" ./config/prod.secret.exs
sed -i -e "s/password:.*,/password: \"$DB_PASSWORD\",/g" ./config/prod.secret.exs
sed -i -e "s/database:.*,/database: \"$DB_NAME\",/g" ./config/prod.secret.exs
sed -i -e "s/hostname:.*,/hostname: \"$DB_HOST\",/g" ./config/prod.secret.exs
sed -i -e "s/GUARDIAN_SECRET_KEY/$GUARDIAN_SECRET_KEY/g" ./config/prod.secret.exs

sed -i -e "s/AUTH_DOMAIN/$AUTH_DOMAIN/g" ./config/prod.secret.exs
sed -i -e "s/AUTH_AUDIENCE/$AUTH_AUDIENCE/g" ./config/prod.secret.exs
sed -i -e "s/AUTH_ISSUER/$AUTH_ISSUER/g" ./config/prod.secret.exs
sed -i -e "s/AUTH_SECRET_KEY/$AUTH_SECRET_KEY/g" ./config/prod.secret.exs


cp ./config/prod.secret.exs ~/tdauth.prod.secret.exs
