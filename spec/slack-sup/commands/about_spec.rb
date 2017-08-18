require 'spec_helper'

describe SlackSup::Commands::About do
  let(:team) { Fabricate(:team) }
  let(:app) { SlackSup::Server.new(team: team) }
  let(:client) { app.send(:client) }
  it 'about' do
    expect(message: "#{SlackRubyBot.config.user} about").to respond_with_slack_message(SlackSup::INFO)
  end
end
