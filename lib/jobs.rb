require "backburner"
require 'redis'

class GenericJob
    include Backburner::Queue

    queue "fakebook"  

    def self.perform(uuid)
        # Load the actual facebook api code.  
        # Done in a load, not a require, to ensure that it is
        # updated every time.
        load File.dirname(__FILE__)+'/fake_facebook_api.rb'

        #Connect to Redis (using the default settings)
        # and rtrieve the data structure from Redis
        cache = Redis.new
        data = JSON.parse cache.get(uuid)

        # Don't double-process things
        return unless data["status"] == 0 
        
        # Redirect stdout to the log file
        orig_stdout = $stdout
        $stdout.reopen("logs/#{data["ticket"]}.txt", "w")
        $stdout.sync = true

        #Instantiate the API. 
        go_headless = data["headless"].nil? ? true : data["headless"]
        api = FakeFacebookApi.new(data['email'],data["password"],data["ticket"], go_headless)
      
        # Delete the password in Redis now that we don't need it anymore
        data["password"] = "DELETED"
        cache.set(uuid,JSON.generate(data))
        
        # Call the method passed in by the string.  
        # For security, check it against the whitelist of allowable methods
        method = data["method"]
        if FakeFacebookApi.allowable_routes.include? "/#{method}" 
            success = api.facebook do
              puts "Initiating #{method}"
              eval "#{method}(data)"
            end
        else
            puts "Invalid method: #{method}"
            success = false
        end
        # On completion, update the status, add an endtime, and save to redis.
        data["status"] = success ? 1 : -1
        end_time = data["end_time"] = Time.now.to_i
        cache.set(uuid,JSON.generate(data))
        
        # Move it from pending to completed
        cache.zrem("pending",uuid)
        cache.zadd("completed",end_time,uuid)

        # Restore stdout.
        $stdout = orig_stdout
    end
end
