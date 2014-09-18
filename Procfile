webserver: thin start --port=$STD_PORT -R config.ru
ssl_webserver: bin/thin_start.sh
redis: redis-server /usr/local/etc/redis.conf
guard: bundle exec guard
beanstalkd: beanstalkd
# worker: bundle exec ruby lib/background_task.rb