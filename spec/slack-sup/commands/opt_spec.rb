require 'spec_helper'

describe SlackSup::Commands::Opt do
  context 'team' do
    include_context :team

    it 'requires a subscription' do
      expect(message: "#{SlackRubyBot.config.user} opt").to respond_with_slack_message(team.subscribe_text)
    end
  end

  context 'subscribed team' do
    include_context :subscribed_team

    context 'on a DM' do
      context 'as an admin' do
        before do
          allow_any_instance_of(Team).to receive(:is_admin?).and_return(true)
        end
        it "shows user's current opt status" do
          expect(message: "#{SlackRubyBot.config.user} opt", channel: 'DM').to respond_with_slack_message(
            'You were not found in any channels.'
          )
        end
        it "shows another user's current opt status" do
          expect(message: "#{SlackRubyBot.config.user} opt <@some_user>", channel: 'DM').to respond_with_slack_message(
            'User <@some_user> was not found in any channels.'
          )
        end
        context 'with a channel' do
          let!(:channel1) { Fabricate(:channel, team: team) }
          let!(:user1) { Fabricate(:user, channel: channel1) }
          let!(:channel2) { Fabricate(:channel, team: team) }
          let!(:user2) { Fabricate(:user, channel: channel2, user_id: user1.user_id, opted_in: false) }
          it 'shows opt in status' do
            expect(message: "#{SlackRubyBot.config.user} opt <@#{user1.user_id}>", channel: 'DM').to respond_with_slack_message(
              "User #{user1.slack_mention} is opted in to #{channel1.slack_mention} and opted out of #{channel2.slack_mention}."
            )
          end
        end
      end
      context 'as a non-admin' do
        before do
          allow_any_instance_of(Team).to receive(:is_admin?).and_return(false)
        end
        it 'requires an admin' do
          expect(message: "#{SlackRubyBot.config.user} opt <@someone>", channel: 'DM').to respond_with_slack_message([
            "Sorry, only <@#{team.activated_user_id}> or a Slack team admin can see whether users are opted in or out."
          ].join("\n"))
        end
      end
    end

    context 'channel' do
      include_context :user

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
            allow_any_instance_of(User).to receive(:channel_admin?).and_return(false)
          end
          it 'requires an admin' do
            expect(message: "#{SlackRubyBot.config.user} opt in #{user.slack_mention}").to respond_with_slack_message(
              "Sorry, only <@#{channel.inviter_id}> or a Slack team admin can opt users in and out."
            )
          end
        end
        context 'as admin' do
          before do
            allow_any_instance_of(User).to receive(:channel_admin?).and_return(true)
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
      end
    end
  end
end
