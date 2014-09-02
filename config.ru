require 'bundler'
Bundler.require

require_relative "app/app.rb"



Dotenv.load
use Rack::SslEnforcer, :http_port => 3000, :https_port => 3001, :before_redirect => Proc.new { |request|
  #keep flash on redirect
  puts "rredirect!"
}

# use Rack::LiveReload, :min_delay => 500, :no_swf => true


run FFB::App
