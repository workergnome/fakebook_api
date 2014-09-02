webserver: thin start --port=3001 -R config.ru
ssl_webserver: rerun --no-growl --pattern "**/*.{rb,coffee,erb,html,ru,yml,slim,md,hbs,env}" -- "thin start --ssl --ssl-key-file ~/.ssl/server.key --port=3000 --ssl-cert-file ~/.ssl/server.crt --debug -R config.ru"
redis: redis-server /usr/local/etc/redis.conf
guard: bundle exec guard
beanstalkd: beanstalkd

# worker: bundle exec ruby lib/background_task.rb