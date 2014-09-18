God.watch do |w|
  w.dir = '/Users/david/Documents/cmu/fakebook_api'
  w.name = "background_process"
  w.start = "bundle exec ruby lib/background_task.rb"
  w.log = "logs/background_task.log"
  w.keepalive
end