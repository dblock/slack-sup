require 'spec_helper'

describe SlackSup::Commands::About do
  let(:team) { Fabricate(:team) }
  let(:app) { SlackSup::Server.new(team:) }
  let(:client) { app.send(:client) }

  it 'returns one admin' do
    expect(message: "#{SlackRubyBot.config.user} admins").to respond_with_slack_message("Team admin is <@#{team.activated_user_id}>.")
  end

  context 'with multiple admins' do
    let!(:another_admin) { Fabricate(:user, team:, is_admin: true) }
    let!(:another_user) { Fabricate(:user, team:) }

    it 'returns multiple admins' do
      expect(message: "#{SlackRubyBot.config.user} admins").to respond_with_slack_message("Team admins are <@#{team.activated_user_id}> and #{another_admin.slack_mention}.")
    end
  end
end
