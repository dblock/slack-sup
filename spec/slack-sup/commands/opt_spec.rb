require 'spec_helper'

describe SlackSup::Commands::Opt do
  let!(:team) { Fabricate(:team) }
  let!(:user) { Fabricate(:user, team: team) }
  let(:app) { SlackSup::Server.new(team: team) }
  let(:client) { app.send(:client) }
  before do
    allow(User).to receive(:find_create_or_update_by_slack_id!).and_return(user)
  end
  context 'opt' do
    it 'requires a subscription' do
      expect(message: "#{SlackRubyBot.config.user} opt", user: user.user_id).to respond_with_slack_message(team.subscribe_text)
    end
    context 'subscribed team' do
      let(:team) { Fabricate(:team, subscribed: true) }
      context 'current user' do
        it 'shows current value of opt' do
          expect(message: "#{SlackRubyBot.config.user} opt", user: user.user_id).to respond_with_slack_message(
            "Hi there #{user.slack_mention}, you're opted into S'Up."
          )
        end
        it 'shows current opt-in' do
          user.update_attributes!(opted_in: true)
          expect(message: "#{SlackRubyBot.config.user} opt", user: user.user_id).to respond_with_slack_message(
            "Hi there #{user.slack_mention}, you're opted into S'Up."
          )
        end
        it 'shows current opt-out' do
          user.update_attributes!(opted_in: false)
          expect(message: "#{SlackRubyBot.config.user} opt", user: user.user_id).to respond_with_slack_message(
            "Hi there #{user.slack_mention}, you're opted out of S'Up."
          )
        end
        it 'opts in' do
          user.update_attributes!(opted_in: false)
          expect(message: "#{SlackRubyBot.config.user} opt in", user: user.user_id).to respond_with_slack_message(
            "Hi there #{user.slack_mention}, you're now opted into S'Up."
          )
          expect(user.reload.opted_in?).to be true
        end
        it 'opts out' do
          user.update_attributes!(opted_in: true)
          expect(message: "#{SlackRubyBot.config.user} opt out", user: user.user_id).to respond_with_slack_message(
            "Hi there #{user.slack_mention}, you're now opted out of S'Up."
          )
          expect(user.reload.opted_in?).to be false
        end
        it 'invalid opt' do
          expect(message: "#{SlackRubyBot.config.user} opt whatever", user: user.user_id).to respond_with_slack_message(
            'You can _opt in_ or _opt out_, but not _opt whatever_.'
          )
        end
      end
      context 'another user' do
        context 'as non admin' do
          before do
            allow_any_instance_of(User).to receive(:team_admin?).and_return(false)
          end
          it 'requires an admin' do
            expect(message: "#{SlackRubyBot.config.user} opt in #{user.slack_mention}").to respond_with_slack_message(
              "Sorry, only <@#{team.activated_user_id}> or a Slack team admin can opt users in and out."
            )
          end
        end
        context 'as admin' do
          before do
            allow_any_instance_of(User).to receive(:team_admin?).and_return(true)
          end
          context 'ignoring sync_user' do
            before do
              allow(team).to receive(:sync_user!)
            end
            it 'opts a user in' do
              user.update_attributes!(opted_in: false)
              expect(message: "#{SlackRubyBot.config.user} opt in #{user.slack_mention}").to respond_with_slack_message(
                "User #{user.slack_mention} is now opted into S'Up."
              )
              expect(user.reload.opted_in).to be true
            end
            it 'opts a user out' do
              user.update_attributes!(opted_in: true)
              expect(message: "#{SlackRubyBot.config.user} opt out #{user.slack_mention}").to respond_with_slack_message(
                "User #{user.slack_mention} is now opted out of S'Up."
              )
              expect(user.reload.opted_in).to be false
            end
            it 'errors on an invalid user' do
              expect(message: "#{SlackRubyBot.config.user} opt in foobar").to respond_with_slack_message(
                "I don't know who foobar is!"
              )
            end
          end
          context 'with sync_user' do
            it 'attempts to sync the user opted in' do
              expect(team).to receive(:sync_user!).with('foobar')
              expect(message: "#{SlackRubyBot.config.user} opt in foobar").to respond_with_slack_message(
                "I don't know who foobar is!"
              )
            end
            it 'syncs user being opted in', vcr: { cassette_name: 'user_info' } do
              expect(message: "#{SlackRubyBot.config.user} opt in username").to respond_with_slack_message(
                "User <@U007> is now opted into S'Up."
              )
            end
          end
        end
      end
    end
  end
end
