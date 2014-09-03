## This is the software for running a background worker.
## It also handles re-queueing anything in pending...that might be a bad idea if there are multiple things going.

$stdout.sync = true # for foreman logging

require "backburner"
require 'redis'
require_relative "jobs.rb"


Backburner.configure do |config|
  config.tube_namespace = "fakebook"
end

cache = Redis.new

cache.zrevrange("pending",0,-1).each do |uuid|
  Backburner.enqueue GenericJob, uuid
end


Backburner.work