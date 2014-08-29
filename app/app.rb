require "sinatra/base"
require 'sinatra/handlebars'
require 'haml'
require "tilt"
require 'sass'
require 'json'
require 'securerandom'
require 'redis'
require "backburner"
require_relative '../lib/jobs'

$stdout.sync = true # for foreman logging
Backburner.configure do |config|
  config.tube_namespace   = "fakebook"
end

module FFB
  class App < Sinatra::Base
    register Sinatra::Handlebars

    handlebars {
      templates '/js/templates.js', ['app/templates/*']
    }

    configure do
      set :layouts_dir, 'views/_layouts'
      set :partials_dir, 'views/_partials'
      set :cache, Redis.new
    end

    get '/' do
      haml :index
    end

    get '/pretty_status/:uuid' do
      uuid = params[:uuid]
      data = settings.cache.get(uuid)
      if data.nil?
        data = {:method => nil, :id => nil, :ticket => uuid, :status => -1}
      else 
        data = JSON.parse data
      end
      data["password"] = "************"
      haml :status, :locals => {:ticket => data}
    end

    get '/status/:uuid' do
      uuid = params[:uuid]
      data = settings.cache.get(uuid)
      if data.nil?
        data = {:method => nil, :id => nil, :ticket => uuid, :status => -1}
      else 
        data = JSON.parse data
      end
      data["password"] = "************"
      return JSON.generate data     
    end

    ["/friend","/poke", "/post"].each do |path|
      post path do
        id = SecureRandom.uuid

        obj = {
          :id => params[:id],
          :method => path.gsub("/",""), 
          :status => 0, 
          :ticket => id, 
          :message => params[:message],
          :email => params[:email],
          :password => params[:password]
        }

        settings.cache.set(id, JSON.generate(obj))
        Backburner.enqueue GenericJob, id
        redirect to("/status/#{id}")
      end
    end
  end
end