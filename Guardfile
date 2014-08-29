guard 'sass', :input => 'app/sass', :output => 'app/public/css'

guard 'livereload' do
  watch(%r{views/.+\.(erb|haml|slim)$})
  watch(%r{public/.+\.(css|js|html)})
end

guard :bundler do
  watch('Gemfile')
end

guard 'coffeescript', :input => 'app/coffee', :output => 'app/public/js'