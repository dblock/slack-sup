ENV['RACK_ENV'] ||= 'development'

require 'bundler/setup'
Bundler.require :default, ENV['RACK_ENV']

Dir[File.expand_path('config/initializers', __dir__) + '/**/*.rb'].sort.each do |file|
  require file
end

Mongoid.load! File.expand_path('config/mongoid.yml', __dir__), ENV['RACK_ENV']

require_relative 'lib/service'
require_relative 'lib/version'
require_relative 'lib/info'
require_relative 'lib/models'
require_relative 'lib/events'
require_relative 'lib/actions'
require_relative 'lib/commands'
require_relative 'lib/api'
require_relative 'lib/app'
