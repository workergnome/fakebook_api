require "backburner"
require 'redis'

class GenericJob
    include Backburner::Queue

    queue "fakebook"  

    def self.perform(uuid)
        load File.dirname(__FILE__)+'/fake_facebook_api.rb'

        cache = Redis.new
        data = JSON.parse cache.get(uuid)
        
        orig_stdout = $stdout
        $stdout.reopen("logs/#{data["ticket"]}.txt", "w")
        $stdout.sync = true

        go_headless = data["headless"].nil? ? true : data["headless"]
        api = FakeFacebookApi.new(data['email'],data["password"],data["ticket"], go_headless)
        data["password"] = "DELETED"
        cache.set(uuid,JSON.generate(data))
        
        method = data["method"]
        success = api.facebook do
          puts "Initiating #{method}"
          eval "#{method}(data)"
        end

        data["status"] = success ? 1 : -1
        cache.set(uuid,JSON.generate(data))
        $stdout = orig_stdout

    end
end
