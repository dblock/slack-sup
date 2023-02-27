require_relative 'app'

NewRelic::Agent.manual_start

SlackSup::App.instance.prepare!
SlackSup::App.instance.start!

SlackRubyBotServer::Service.start!

run Api::Middleware.instance
