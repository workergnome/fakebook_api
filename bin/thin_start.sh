#!/bin/bash

if [ "$RACK_ENV" == "development" ]; then
  exec rerun --no-growl --pattern "**/*.{rb,coffee,erb,html,ru,yml,slim,md,hbs,env}" \
        -- "thin start --ssl --ssl-key-file $SSL_KEY  \
        --ssl-cert-file $SSL_CERT \
        --port=$SSL_PORT \
        --debug -R config.ru"
else
  exec bundle exec thin start --ssl --ssl-key-file $SSL_KEY  \
        --ssl-cert-file $SSL_CERT \
        --port=$SSL_PORT \
        --debug -R config.ru
fi