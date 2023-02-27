require 'spec_helper'

describe SlackSup::Commands::About do
  include_context :team

  it 'about' do
    expect(message: '@sup about').to respond_with_slack_message(SlackSup::INFO)
  end
end
