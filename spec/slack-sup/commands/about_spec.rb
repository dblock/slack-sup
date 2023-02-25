require 'spec_helper'

describe SlackSup::Commands::About do
  it 'about' do
    expect(message: "#{SlackRubyBot.config.user} about").to respond_with_slack_message(SlackSup::INFO)
  end
end
