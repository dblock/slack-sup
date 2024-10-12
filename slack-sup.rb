ENV['RACK_ENV'] ||= 'development'

require 'bundler/setup'
Bundler.require :default, ENV.fetch('RACK_ENV', nil)

Dir[File.expand_path('config/initializers', __dir__) + '/**/*.rb'].each do |file|
  require file
end

Mongoid.load! File.expand_path('config/mongoid.yml', __dir__), ENV.fetch('RACK_ENV', nil)

SlackRubyBotServer.configure do |config|
  config.oauth_version = :v1
  config.oauth_scope = ['bot', 'users.profile:read']
end

require 'slack-ruby-bot'
require 'slack-sup/version'
require 'slack-sup/service'
require 'slack-sup/info'
require 'slack-sup/models'
require 'slack-sup/api'
require 'slack-sup/app'
require 'slack-sup/server'
require 'slack-sup/commands'

SlackRubyBotServer::RealTime.configure do |config|
  config.server_class = SlackSup::Server
end
