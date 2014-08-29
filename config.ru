require 'dotenv'
Dotenv.load

require_relative "app/app.rb"
require 'rack-livereload'

require 'rack/ssl'
use Rack::SSL

require 'bundler'
Bundler.require

use Rack::LiveReload, :min_delay => 500, :no_swf => true


require 'beanstalkd_view'
ENV['BEANSTALK_URL'] ||= 'beanstalk://localhost/'
map "/beanstalk" do
  run BeanstalkdView::Server
end

run FFB::App
