require_relative 'app'

NewRelic::Agent.manual_start

SlackSup::App.instance.prepare!

SlackRubyBotServer::Service.start!

run Api::Middleware.instance
