require "sinatra/base"
require 'sinatra/handlebars'
require 'haml'
require "tilt"
require 'sass'
require 'json'
require 'securerandom'
require 'redis'
require "backburner"
require 'fileutils'
require_relative '../lib/jobs'
require_relative '../lib/fake_facebook_api'

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

    helpers do
      def valid_uuid?(uuid)
        if  (params[:uuid] =~ (/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i)).nil?
         halt 400, "Invalid UUID"
        else
          true
        end
      end
    end

    get '/' do
      obj = {}
      obj[:pending] = settings.cache.zcount("pending","-inf","+inf")
      obj[:completed] = settings.cache.zcount("completed","-inf","+inf")
      haml :index, :locals => obj
    end

    get '/clear_jobs' do
      amount_cleared = settings.cache.zremrangebyscore("pending","-inf","+inf")

      deleted = 0
      current_tube = Backburner::Worker.connection.tubes['fakebook.']
      while current_tube.peek(:ready)
         job = current_tube.reserve
         job.delete
         deleted +=1
      end
      "Cleared #{amount_cleared}, deleted #{deleted}"
    end

    post '/device_log' do
      # Sanity check—will only resolve on 40 digit hex string for ids
      # halt 400, "Invalid UDID" unless params[:id] && (params[:id] =~ /[0-9A-Z]/i) == 0 && params[:id].length == 36

      FileUtils::mkdir_p "#{ENV['LOG_LOCATION']}#{params[:id]}"
      File.open("#{ENV['LOG_LOCATION']}#{params[:id]}/master_#{params[:type]}.log", "a") { |file| file.write params[:data]+"\n" }.to_s
    end
    
    get '/pretty_status/:uuid' do
      #security check — we're evaluating hashes directly from web input.
      uuid = params[:uuid]
      if valid_uuid?(uuid)
        data = settings.cache.get(uuid)

        # Handle missing data
        if data.nil?
          data = {:method => nil, :id => nil, :ticket => uuid, :status => -1}
        else 
          data = JSON.parse data
        end
        
        # Hide password
        data["password"] = "************"
        haml :status, :locals => {:ticket => data}
      end
    end

    get '/screenshot/:uuid' do
      #security check — we're evaluating filenames directly from web input.
      if valid_uuid?(params[:uuid])
        content_type 'image/png'
        File.read(File.join('screenshots', "#{params[:uuid]}.png"))
      else
        "Invalid UUID."
      end
    end

    get "/status" do
      pending = settings.cache.zrevrange("pending",0,-1).collect do |uuid|
        val = JSON.parse settings.cache.get(uuid)
        val.delete "password"
        val
      end
      complete = settings.cache.zrevrange("completed",0,10).collect do |uuid|
        val =JSON.parse settings.cache.get(uuid)
        val.delete "password"
        val
      end
      obj = {complete: complete, pending: pending}
      json obj
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

    FakeFacebookApi::allowable_routes.each do |path|
      post path do
        id = SecureRandom.uuid

        obj = {
          :id => params[:id],
          :method => path.gsub("/",""), 
          :status => 0, 
          :ticket => id, 
          :message => params[:message],
          :email => params[:email],
          :password => params[:password],
          :friend_name => params[:friend_name],
          :headless => (params[:headless].nil?  ? true : false),
          :start_time => Time.now.to_i,
          :end_time => nil
        }

        settings.cache.set(id, JSON.generate(obj))
        settings.cache.zadd("pending",obj[:start_time],id)
        Backburner.enqueue GenericJob, id
        redirect to("/status/#{id}")
      end
    end
  end
end