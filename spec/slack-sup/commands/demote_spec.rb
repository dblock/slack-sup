require 'spec_helper'

describe SlackSup::Commands::Demote do
  let!(:team) { Fabricate(:team) }
  let!(:user) { Fabricate(:user, team:) }
  let!(:user2) { Fabricate(:user, team:) }
  let(:app) { SlackSup::Server.new(team:) }
  let(:client) { app.send(:client) }

  before do
    allow(User).to receive(:find_create_or_update_by_slack_id!).and_return(user)
  end

  context 'demote' do
    it 'requires a subscription' do
      expect(message: "#{SlackRubyBot.config.user} demote", user: user.user_id).to respond_with_slack_message(team.subscribe_text)
    end

    context 'subscribed team' do
      let(:team) { Fabricate(:team, subscribed: true) }

      context 'another user' do
        context 'as non admin' do
          before do
            allow_any_instance_of(User).to receive(:team_admin?).and_return(false)
          end

          it 'requires an admin' do
            expect(message: "#{SlackRubyBot.config.user} demote #{user2.slack_mention}").to respond_with_slack_message(
              "Sorry, only <@#{team.activated_user_id}> can demote users."
            )
          end
        end

        context 'as admin' do
          before do
            allow_any_instance_of(User).to receive(:team_admin?).and_return(true)
          end

          it 'cannot demote self' do
            expect(team).to receive(:sync_user!).with(user.user_id)
            expect(message: "#{SlackRubyBot.config.user} demote #{user.slack_mention}").to respond_with_slack_message(
              'Sorry, you cannot demote yourself.'
            )
          end

          it 'demotes a user' do
            expect(team).to receive(:sync_user!).with(user2.user_id)
            user2.update_attributes!(is_admin: true)
            expect(message: "#{SlackRubyBot.config.user} demote #{user2.slack_mention}").to respond_with_slack_message(
              "User #{user2.slack_mention} is no longer S'Up admin."
            )
            expect(user2.reload.is_admin).to be false
          end

          it 'says user already demoted' do
            expect(team).to receive(:sync_user!).with(user2.user_id)
            user2.update_attributes!(is_admin: false)
            expect(message: "#{SlackRubyBot.config.user} demote #{user2.slack_mention}").to respond_with_slack_message(
              "User #{user2.slack_mention} is not S'Up admin."
            )
            expect(user2.reload.is_admin).to be false
          end

          it 'errors on an invalid user' do
            expect(team).to receive(:sync_user!).with('foobar')
            expect(message: "#{SlackRubyBot.config.user} demote foobar").to respond_with_slack_message(
              "I don't know who foobar is!"
            )
          end

          it 'errors on no user' do
            expect(message: "#{SlackRubyBot.config.user} demote").to respond_with_slack_message(
              'Sorry, demote @someone.'
            )
          end
        end
      end
    end
  end
end
