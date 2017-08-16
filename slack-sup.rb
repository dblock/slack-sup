ENV['RACK_ENV'] ||= 'development'

require 'bundler/setup'
Bundler.require :default, ENV['RACK_ENV']

Dir[File.expand_path('../config/initializers', __FILE__) + '/**/*.rb'].each do |file|
  require file
end

Mongoid.load! File.expand_path('../config/mongoid.yml', __FILE__), ENV['RACK_ENV']

require 'slack-ruby-bot'
require 'slack-sup/version'
require 'slack-sup/service'
require 'slack-sup/info'
require 'slack-sup/models'
require 'slack-sup/api'
require 'slack-sup/app'
require 'slack-sup/server'
require 'slack-sup/commands'
