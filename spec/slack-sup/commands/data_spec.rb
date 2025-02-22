require 'spec_helper'

describe SlackSup::Commands::Data do
  let!(:team) { Fabricate(:team) }
  let!(:user) { Fabricate(:user, team:) }
  let(:app) { SlackSup::Server.new(team:) }
  let(:client) { app.send(:client) }

  before do
    allow(User).to receive(:find_create_or_update_by_slack_id!).and_return(user)
  end

  context 'data' do
    it 'requires a subscription' do
      expect(message: "#{SlackRubyBot.config.user} data", user: user.user_id).to respond_with_slack_message(team.subscribe_text)
    end

    context 'subscribed team' do
      let(:team) { Fabricate(:team, subscribed: true) }

      context 'another user' do
        context 'as non admin' do
          before do
            allow_any_instance_of(User).to receive(:team_admin?).and_return(false)
          end

          it 'requires an admin' do
            expect(message: "#{SlackRubyBot.config.user} data").to respond_with_slack_message(
              "Sorry, only #{user.team.team_admins_slack_mentions.or} can download data."
            )
          end
        end

        context 'as admin' do
          before do
            allow_any_instance_of(User).to receive(:team_admin?).and_return(true)
            allow_any_instance_of(Team).to receive(:short_lived_token).and_return('token')
          end

          it 'errors without rounds' do
            expect do
              expect(message: "#{SlackRubyBot.config.user} data 111").to respond_with_slack_message(
                "Sorry, I didn't find any rounds, try `all` to get all data."
              )
            end.not_to change(Export, :count)
          end

          it 'errors with an invalid number of rounds' do
            expect(message: "#{SlackRubyBot.config.user} data -1").to respond_with_slack_message(
              'Sorry, -1 is not a valid number of rounds.'
            )
          end

          context 'with 3 most recent rounds' do
            before do
              allow(team).to receive(:sync!)
              3.times { team.sup! }
            end

            it 'prepares team data' do
              expect do
                expect(message: "#{SlackRubyBot.config.user} data").to respond_with_slack_message(
                  "Hey #{user.slack_mention}, we will prepare your team data for the most recent round in the next few minutes, please check your DMs for a link."
                )
              end.to change(Export, :count).by(1)
              export = team.exports.last
              expect(export.max_rounds_count).to eq 1
            end

            it 'prepares team data for the last N rounds' do
              expect do
                expect(message: "#{SlackRubyBot.config.user} data 3").to respond_with_slack_message(
                  "Hey #{user.slack_mention}, we will prepare your team data for 3 most recent rounds in the next few minutes, please check your DMs for a link."
                )
              end.to change(Export, :count).by(1)
              export = team.exports.last
              expect(export.max_rounds_count).to eq 3
            end

            it 'prepares team data for all rounds' do
              expect do
                expect(message: "#{SlackRubyBot.config.user} data all").to respond_with_slack_message(
                  "Hey #{user.slack_mention}, we will prepare your team data for all rounds in the next few minutes, please check your DMs for a link."
                )
              end.to change(Export, :count).by(1)
              export = team.exports.last
              expect(export.max_rounds_count).to be_nil
            end

            it 'errors telling the caller the max number of rounds available across channels' do
              expect do
                expect(message: "#{SlackRubyBot.config.user} data 5").to respond_with_slack_message(
                  'Sorry, I only found 3 rounds, try 1, 3 or `all`.'
                )
              end.not_to change(Export, :count)
            end

            it 'does not allow for more than one active request' do
              Export.create!(team:, user_id: 'user', exported: false)

              expect do
                expect(message: "#{SlackRubyBot.config.user} data").to respond_with_slack_message(
                  'Hey <@user>, we are still working on your previous request.'
                )
              end.not_to change(Export, :count)
            end

            it 'allow for more than one active request once the previous one is completed' do
              Export.create!(team:, user_id: 'user', exported: true)

              expect do
                expect(message: "#{SlackRubyBot.config.user} data").to respond_with_slack_message(
                  "Hey #{user.slack_mention}, we will prepare your team data for the most recent round in the next few minutes, please check your DMs for a link."
                )
              end.to change(Export, :count).by(1)
            end
          end
        end
      end
    end
  end
end
