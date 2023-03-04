require 'spec_helper'

describe SlackSup::Commands::Opt do
  context 'team' do
    include_context :team

    it 'requires a subscription' do
      expect(message: '@sup opt').to respond_with_slack_message(team.subscribe_text)
    end
  end

  context 'subscribed team' do
    include_context :subscribed_team

    context 'dm' do
      context 'as an admin' do
        before do
          allow_any_instance_of(Team).to receive(:is_admin?).and_return(true)
        end
        it "shows user's current opt status" do
          expect(message: '@sup opt', channel: 'DM').to respond_with_slack_message(
            'You were not found in any channels.'
          )
        end
        it "shows another user's current opt status" do
          expect(message: '@sup opt <@some_user>', channel: 'DM').to respond_with_slack_message(
            'User <@some_user> was not found in any channels.'
          )
        end
        context 'with a channel' do
          let!(:channel1) { Fabricate(:channel, team: team) }
          let!(:user1) { Fabricate(:user, channel: channel1) }
          let!(:channel2) { Fabricate(:channel, team: team) }
          let!(:user2) { Fabricate(:user, channel: channel2, user_id: user1.user_id, opted_in: false) }
          it 'shows opt in status' do
            expect(message: "@sup opt <@#{user1.user_id}>", channel: 'DM').to respond_with_slack_message(
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
          expect(message: '@sup opt <@someone>', channel: 'DM').to respond_with_slack_message([
            "Sorry, only <@#{team.activated_user_id}> or a Slack team admin can opt users in or out."
          ].join("\n"))
        end
        it 'lists channels opted in' do
          expect(message: '@sup opt', channel: 'DM').to respond_with_slack_message(
            'You were not found in any channels.'
          )
        end
        context 'opted into channels' do
          let!(:channel1) { Fabricate(:channel, team: team) }
          let!(:channel2) { Fabricate(:channel, team: team) }
          let!(:channel3) { Fabricate(:channel, team: team) }
          context 'self' do
            let!(:user1) { Fabricate(:user, channel: channel1, user_id: 'user') }
            let!(:user2) { Fabricate(:user, channel: channel2, user_id: 'user', opted_in: false) }
            it 'lists channels opted in' do
              expect(message: '@sup opt', channel: 'DM').to respond_with_slack_message(
                "You are opted in to #{channel1.slack_mention}, opted out of #{channel2.slack_mention} and not a member of #{channel3.slack_mention}."
              )
            end
            it 'opts out of a channel' do
              expect(message: "@sup opt out #{channel1.slack_mention}", channel: 'DM').to respond_with_slack_message(
                "You are now opted out of #{channel1.slack_mention}."
              )
            end
            it 'opts out of multiple channels' do
              expect(message: "@sup opt out #{channel1.slack_mention} #{channel2.slack_mention}", channel: 'DM').to respond_with_slack_message(
                "You are now opted out of #{channel1.slack_mention} and #{channel2.slack_mention}."
              )
            end
            it 'remains opted out of a channel' do
              expect(message: "@sup opt out #{channel2.slack_mention}", channel: 'DM').to respond_with_slack_message(
                "You are opted out of #{channel2.slack_mention}."
              )
            end
            it 'opts in a channel' do
              expect(message: "@sup opt in #{channel2.slack_mention}", channel: 'DM').to respond_with_slack_message(
                "You are now opted in to #{channel2.slack_mention}."
              )
            end
            it 'remains opted in a channel' do
              expect(message: "@sup opt in #{channel1.slack_mention}", channel: 'DM').to respond_with_slack_message(
                "You are opted in to #{channel1.slack_mention}."
              )
            end
            it 'opts into multiple channels' do
              expect(message: "@sup opt in #{channel1.slack_mention} #{channel2.slack_mention}", channel: 'DM').to respond_with_slack_message(
                "You are now opted in to #{channel1.slack_mention} and #{channel2.slack_mention}."
              )
            end
            it 'opts out of multiple channels' do
              expect(message: "@sup opt out #{channel1.slack_mention} #{channel2.slack_mention}", channel: 'DM').to respond_with_slack_message(
                "You are now opted out of #{channel1.slack_mention} and #{channel2.slack_mention}."
              )
            end
            it 'fails on an unknown channel' do
              expect(message: '@sup opt in <#invalid>', channel: 'DM').to respond_with_slack_message(
                "Sorry, I can't find an existing S'Up channel <#invalid>."
              )
            end
            it 'fails on a channel by name' do
              expect(message: '@sup opt in #invalid', channel: 'DM').to respond_with_slack_message(
                "Sorry, I don't understand who or what #invalid is."
              )
            end
          end
          context 'others' do
            let!(:user1) { Fabricate(:user, channel: channel1) }
            let!(:user2) { Fabricate(:user, channel: channel1) }
            let!(:user1_channel2) { Fabricate(:user, channel: channel2, user_id: user1.user_id, opted_in: false) }
            let!(:user2_channel2) { Fabricate(:user, channel: channel2, user_id: user2.user_id, opted_in: false) }
            before do
              allow_any_instance_of(Team).to receive(:is_admin?).and_return(true)
            end
            context 'one user' do
              it 'lists channels opted in' do
                expect(message: "@sup opt #{user1.slack_mention}", channel: 'DM').to respond_with_slack_message(
                  "User #{user1.slack_mention} is opted in to #{channel1.slack_mention}, opted out of #{channel2.slack_mention} and not a member of #{channel3.slack_mention}."
                )
              end
              it 'opts out of a channel' do
                expect(message: "@sup opt out #{user1.slack_mention} #{channel1.slack_mention}", channel: 'DM').to respond_with_slack_message(
                  "User #{user1.slack_mention} is now opted out of #{channel1.slack_mention}."
                )
              end
              it 'opts out of multiple channels' do
                expect(message: "@sup opt out #{user1.slack_mention} #{channel1.slack_mention} #{channel2.slack_mention}", channel: 'DM').to respond_with_slack_message(
                  "User #{user1.slack_mention} is now opted out of #{channel1.slack_mention} and #{channel2.slack_mention}."
                )
              end
              it 'remains opted out of a channel' do
                expect(message: "@sup opt out #{user1.slack_mention} #{channel2.slack_mention}", channel: 'DM').to respond_with_slack_message(
                  "User #{user1.slack_mention} is opted out of #{channel2.slack_mention}."
                )
              end
              it 'opts in a channel' do
                expect(message: "@sup opt in #{user1.slack_mention} #{channel2.slack_mention}", channel: 'DM').to respond_with_slack_message(
                  "User #{user1.slack_mention} is now opted in to #{channel2.slack_mention}."
                )
              end
              it 'remains opted in a channel' do
                expect(message: "@sup opt in #{user1.slack_mention} #{channel1.slack_mention}", channel: 'DM').to respond_with_slack_message(
                  "User #{user1.slack_mention} is opted in to #{channel1.slack_mention}."
                )
              end
              it 'opts into multiple channels' do
                expect(message: "@sup opt in #{user1.slack_mention} #{channel1.slack_mention} #{channel2.slack_mention}", channel: 'DM').to respond_with_slack_message(
                  "User #{user1.slack_mention} is now opted in to #{channel1.slack_mention} and #{channel2.slack_mention}."
                )
              end
              it 'opts out of multiple channels' do
                expect(message: "@sup opt out #{user1.slack_mention} #{channel1.slack_mention} #{channel2.slack_mention}", channel: 'DM').to respond_with_slack_message(
                  "User #{user1.slack_mention} is now opted out of #{channel1.slack_mention} and #{channel2.slack_mention}."
                )
              end
              it 'fails on an unknown channel' do
                expect(message: "@sup opt in #{user1.slack_mention} <#invalid>", channel: 'DM').to respond_with_slack_message(
                  "Sorry, I can't find an existing S'Up channel <#invalid>."
                )
              end
              it 'fails on a channel by name' do
                expect(message: "@sup opt in #{user1.slack_mention} #invalid", channel: 'DM').to respond_with_slack_message(
                  "Sorry, I don't understand who or what #invalid is."
                )
              end
            end
            context 'two users' do
              it 'lists channels opted in' do
                expect(message: "@sup opt #{user1.slack_mention} #{user2.slack_mention}", channel: 'DM').to respond_with_slack_message([
                  "User #{user1.slack_mention} is opted in to #{channel1.slack_mention}, opted out of #{channel2.slack_mention} and not a member of #{channel3.slack_mention}.",
                  "User #{user2.slack_mention} is opted in to #{channel1.slack_mention}, opted out of #{channel2.slack_mention} and not a member of #{channel3.slack_mention}."
                ].join("\n"))
              end
              it 'opts out of a channel' do
                expect(message: "@sup opt out #{user1.slack_mention} #{user2.slack_mention} #{channel1.slack_mention}", channel: 'DM').to respond_with_slack_message([
                  "User #{user1.slack_mention} is now opted out of #{channel1.slack_mention}.",
                  "User #{user2.slack_mention} is now opted out of #{channel1.slack_mention}."
                ].join("\n"))
              end
              it 'opts out of multiple channels' do
                expect(message: "@sup opt out #{user1.slack_mention} #{user2.slack_mention} #{channel1.slack_mention} #{channel2.slack_mention}", channel: 'DM').to respond_with_slack_message([
                  "User #{user1.slack_mention} is now opted out of #{channel1.slack_mention} and #{channel2.slack_mention}.",
                  "User #{user2.slack_mention} is now opted out of #{channel1.slack_mention} and #{channel2.slack_mention}."
                ].join("\n"))
              end
              it 'remains opted out of a channel' do
                expect(message: "@sup opt out #{user1.slack_mention} #{user2.slack_mention} #{channel2.slack_mention}", channel: 'DM').to respond_with_slack_message([
                  "User #{user1.slack_mention} is opted out of #{channel2.slack_mention}.",
                  "User #{user2.slack_mention} is opted out of #{channel2.slack_mention}."
                ].join("\n"))
              end
              it 'opts in a channel' do
                expect(message: "@sup opt in #{user1.slack_mention} #{user2.slack_mention} #{channel2.slack_mention}", channel: 'DM').to respond_with_slack_message([
                  "User #{user1.slack_mention} is now opted in to #{channel2.slack_mention}.",
                  "User #{user2.slack_mention} is now opted in to #{channel2.slack_mention}."
                ].join("\n"))
              end
              it 'remains opted in a channel' do
                expect(message: "@sup opt in #{user1.slack_mention} #{user2.slack_mention} #{channel1.slack_mention}", channel: 'DM').to respond_with_slack_message([
                  "User #{user1.slack_mention} is opted in to #{channel1.slack_mention}.",
                  "User #{user2.slack_mention} is opted in to #{channel1.slack_mention}."
                ].join("\n"))
              end
              it 'opts into multiple channels' do
                expect(message: "@sup opt in #{user1.slack_mention} #{user2.slack_mention} #{channel1.slack_mention} #{channel2.slack_mention}", channel: 'DM').to respond_with_slack_message([
                  "User #{user1.slack_mention} is now opted in to #{channel1.slack_mention} and #{channel2.slack_mention}.",
                  "User #{user2.slack_mention} is now opted in to #{channel1.slack_mention} and #{channel2.slack_mention}."
                ].join("\n"))
              end
              it 'opts out of multiple channels' do
                expect(message: "@sup opt out #{user1.slack_mention} #{user2.slack_mention} #{channel1.slack_mention} #{channel2.slack_mention}", channel: 'DM').to respond_with_slack_message([
                  "User #{user1.slack_mention} is now opted out of #{channel1.slack_mention} and #{channel2.slack_mention}.",
                  "User #{user2.slack_mention} is now opted out of #{channel1.slack_mention} and #{channel2.slack_mention}."
                ].join("\n"))
              end
              it 'fails on an unknown channel' do
                expect(message: "@sup opt in #{user1.slack_mention} #{user2.slack_mention} <#invalid>", channel: 'DM').to respond_with_slack_message(
                  "Sorry, I can't find an existing S'Up channel <#invalid>."
                )
              end
              it 'fails on a channel by name' do
                expect(message: "@sup opt in #{user1.slack_mention} #{user2.slack_mention} #invalid", channel: 'DM').to respond_with_slack_message(
                  "Sorry, I don't understand who or what #invalid is."
                )
              end
            end
          end
        end
      end
    end

    context 'channel' do
      include_context :user

      before do
        allow_any_instance_of(Slack::Web::Client).to receive(:conversations_info)
      end

      context 'current user' do
        it 'shows current value of opt' do
          expect(message: '@sup opt', user: user.user_id).to respond_with_slack_message(
            'You are opted in to <#channel>.'
          )
        end
        it 'shows current opt-in' do
          user.update_attributes!(opted_in: true)
          expect(message: '@sup opt', user: user.user_id).to respond_with_slack_message(
            'You are opted in to <#channel>.'
          )
        end
        it 'shows current opt-out' do
          user.update_attributes!(opted_in: false)
          expect(message: '@sup opt', user: user.user_id).to respond_with_slack_message(
            'You are opted out of <#channel>.'
          )
        end
        it 'opts in' do
          user.update_attributes!(opted_in: false)
          expect(message: '@sup opt in', user: user.user_id).to respond_with_slack_message(
            'You are now opted in to <#channel>.'
          )
          expect(user.reload.opted_in?).to be true
        end
        it 'opts out' do
          user.update_attributes!(opted_in: true)
          expect(message: '@sup opt out', user: user.user_id).to respond_with_slack_message(
            'You are now opted out of <#channel>.'
          )
          expect(user.reload.opted_in?).to be false
        end
        it 'invalid opt' do
          expect(message: '@sup opt whatever', user: user.user_id).to respond_with_slack_message(
            "Sorry, I don't understand who or what whatever is."
          )
        end
      end
      context 'another user' do
        context 'as non admin' do
          before do
            allow_any_instance_of(User).to receive(:channel_admin?).and_return(false)
          end
          it 'requires an admin' do
            expect(message: "@sup opt in #{user.slack_mention}").to respond_with_slack_message(
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
            expect(message: "@sup opt in #{user.slack_mention}").to respond_with_slack_message(
              "User #{user.slack_mention} is now opted in to <#channel>."
            )
            expect(user.reload.opted_in).to be true
          end
          it 'opts a user out' do
            user.update_attributes!(opted_in: true)
            expect(message: "@sup opt out #{user.slack_mention}").to respond_with_slack_message(
              "User #{user.slack_mention} is now opted out of <#channel>."
            )
            expect(user.reload.opted_in).to be false
          end
          it 'errors on an invalid user' do
            expect(message: '@sup opt in foobar').to respond_with_slack_message(
              "Sorry, I don't understand who or what foobar is."
            )
          end
        end
      end
    end
  end
end
