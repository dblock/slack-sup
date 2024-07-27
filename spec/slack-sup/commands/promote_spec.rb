require 'spec_helper'

describe SlackSup::Commands::Promote do
  let!(:team) { Fabricate(:team) }
  let!(:user) { Fabricate(:user, team: team) }
  let!(:user2) { Fabricate(:user, team: team) }
  let(:app) { SlackSup::Server.new(team: team) }
  let(:client) { app.send(:client) }
  before do
    allow(User).to receive(:find_create_or_update_by_slack_id!).and_return(user)
  end
  context 'promote' do
    it 'requires a subscription' do
      expect(message: "#{SlackRubyBot.config.user} promote", user: user.user_id).to respond_with_slack_message(team.subscribe_text)
    end
    context 'subscribed team' do
      let(:team) { Fabricate(:team, subscribed: true) }
      context 'another user' do
        context 'as non admin' do
          before do
            allow_any_instance_of(User).to receive(:team_admin?).and_return(false)
          end
          it 'requires an admin' do
            expect(message: "#{SlackRubyBot.config.user} promote #{user2.slack_mention}").to respond_with_slack_message(
              "Sorry, only <@#{team.activated_user_id}> can promote users."
            )
          end
        end
        context 'as admin' do
          before do
            allow_any_instance_of(User).to receive(:team_admin?).and_return(true)
          end
          it 'cannot promote self' do
            expect(team).to receive(:sync_user!).with(user.user_id)
            expect(message: "#{SlackRubyBot.config.user} promote #{user.slack_mention}").to respond_with_slack_message(
              'Sorry, you cannot promote yourself.'
            )
          end
          it 'promotes a user' do
            expect(team).to receive(:sync_user!).with(user2.user_id)
            user2.update_attributes!(is_admin: false)
            expect(message: "#{SlackRubyBot.config.user} promote #{user2.slack_mention}").to respond_with_slack_message(
              "User #{user2.slack_mention} is now S'Up admin."
            )
            expect(user2.reload.is_admin).to be true
          end
          it 'says user already promoted' do
            expect(team).to receive(:sync_user!).with(user2.user_id)
            user2.update_attributes!(is_admin: true)
            expect(message: "#{SlackRubyBot.config.user} promote #{user2.slack_mention}").to respond_with_slack_message(
              "User #{user2.slack_mention} is already S'Up admin."
            )
            expect(user2.reload.is_admin).to be true
          end
          it 'errors on an invalid user' do
            expect(team).to receive(:sync_user!).with('foobar')
            expect(message: "#{SlackRubyBot.config.user} promote foobar").to respond_with_slack_message(
              "I don't know who foobar is!"
            )
          end
          it 'errors on no user' do
            expect(message: "#{SlackRubyBot.config.user} promote").to respond_with_slack_message(
              'Sorry, promote @someone.'
            )
          end
        end
      end
    end
  end
end
