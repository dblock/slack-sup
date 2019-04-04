$LOAD_PATH.unshift(File.dirname(__FILE__))

ENV['RACK_ENV'] ||= 'development'

require 'bundler/setup'
Bundler.require :default, ENV['RACK_ENV']

require 'slack-ruby-bot-server'
require 'slack-sup'

SlackRubyBotServer.configure do |config|
  config.server_class = SlackSup::Server
end

NewRelic::Agent.manual_start

SlackSup::App.instance.prepare!

Thread.abort_on_exception = true

Thread.new do
  SlackRubyBotServer::Service.instance.start_from_database!
  SlackSup::App.instance.after_start!
end

run Api::Middleware.instance
