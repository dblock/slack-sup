require 'spec_helper'

describe SlackSup::Commands::Set, vcr: { cassette_name: 'user_info' } do
  let!(:team) { Fabricate(:team) }
  let(:app) { SlackSup::Server.new(team: team) }
  let(:client) { app.send(:client) }
  let(:admin) { Fabricate(:user, team: team, user_name: 'username', is_admin: true) }
  context 'admin' do
    before do
      expect(User).to receive(:find_create_or_update_by_slack_id!).and_return(admin)
    end
    it 'gives help' do
      expect(message: "#{SlackRubyBot.config.user} set").to respond_with_slack_message(
        'Missing setting, eg. _set api off_.'
      )
    end
    context 'api' do
      it 'shows current value of API on' do
        team.update_attributes!(api: true)
        expect(message: "#{SlackRubyBot.config.user} set api").to respond_with_slack_message(
          "API for team #{team.name} is on!\n#{team.api_url}"
        )
      end
      it 'shows current value of API off' do
        team.update_attributes!(api: false)
        expect(message: "#{SlackRubyBot.config.user} set api").to respond_with_slack_message(
          "API for team #{team.name} is off."
        )
      end
      it 'enables API' do
        expect(message: "#{SlackRubyBot.config.user} set api on").to respond_with_slack_message(
          "API for team #{team.name} is on!\n#{team.api_url}"
        )
        expect(team.reload.api).to be true
      end
      it 'disables API with set' do
        team.update_attributes!(api: true)
        expect(message: "#{SlackRubyBot.config.user} set api off").to respond_with_slack_message(
          "API for team #{team.name} is off."
        )
        expect(team.reload.api).to be false
      end
      it 'disables API with unset' do
        team.update_attributes!(api: true)
        expect(message: "#{SlackRubyBot.config.user} unset api").to respond_with_slack_message(
          "API for team #{team.name} is off."
        )
        expect(team.reload.api).to be false
      end
      context 'with API_URL' do
        before do
          ENV['API_URL'] = 'http://local.api'
        end
        after do
          ENV.delete 'API_URL'
        end
        it 'shows current value of API on with API URL' do
          team.update_attributes!(api: true)
          expect(message: "#{SlackRubyBot.config.user} set api").to respond_with_slack_message(
            "API for team #{team.name} is on!\nhttp://local.api/teams/#{team.id}"
          )
        end
        it 'shows current value of API off without API URL' do
          team.update_attributes!(api: false)
          expect(message: "#{SlackRubyBot.config.user} set api").to respond_with_slack_message(
            "API for team #{team.name} is off."
          )
        end
      end
    end
    context 'day' do
      it 'defaults to Monday' do
        expect(message: "#{SlackRubyBot.config.user} set day").to respond_with_slack_message(
          "Team S'Up is on Monday."
        )
      end
      it 'shows current value of sup day' do
        team.update_attributes!(sup_wday: 2)
        expect(message: "#{SlackRubyBot.config.user} set day").to respond_with_slack_message(
          "Team S'Up is on Tuesday."
        )
      end
      it 'changes day' do
        expect(message: "#{SlackRubyBot.config.user} set day friday").to respond_with_slack_message(
          "Team S'Up is now on Friday."
        )
        expect(team.reload.sup_wday).to eq 5
      end
      it 'errors set on an invalid day' do
        expect(message: "#{SlackRubyBot.config.user} set day foobar").to respond_with_slack_message(
          "Day _foobar_ is invalid, try _Monday_, _Tuesday_, etc. Team S'Up is on Monday."
        )
      end
    end
    context 'invalid' do
      it 'errors set' do
        expect(message: "#{SlackRubyBot.config.user} set invalid on").to respond_with_slack_message(
          'Invalid setting _invalid_, you can _set api on|off_ or _set day_.'
        )
      end
      it 'errors unset' do
        expect(message: "#{SlackRubyBot.config.user} unset invalid").to respond_with_slack_message(
          'Invalid setting _invalid_, you can _unset api_.'
        )
      end
    end
  end
  context 'not admin' do
    context 'api' do
      it 'cannot set api' do
        expect(message: "#{SlackRubyBot.config.user} set api true").to respond_with_slack_message(
          'Only a Slack team admin can do this, sorry.'
        )
      end
      it 'can see api value' do
        expect(message: "#{SlackRubyBot.config.user} set api").to respond_with_slack_message(
          "API for team #{team.name} is on!\n#{team.api_url}"
        )
      end
      it 'cannot set day' do
        expect(message: "#{SlackRubyBot.config.user} set day tuesday").to respond_with_slack_message(
          "Team S'Up is on Monday. Only a Slack team admin can change that, sorry."
        )
      end
      it 'can see sup day' do
        expect(message: "#{SlackRubyBot.config.user} set day").to respond_with_slack_message(
          "Team S'Up is on Monday."
        )
      end
    end
  end
end
