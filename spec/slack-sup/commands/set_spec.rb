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
        'Missing setting, see _help_ for available options.'
      )
    end
    context 'api' do
      it 'shows current value of API on' do
        team.update_attributes!(api: true)
        expect(message: "#{SlackRubyBot.config.user} set api").to respond_with_slack_message(
          "Team data access via the API is on.\n#{team.api_url}"
        )
      end
      it 'shows current value of API off' do
        team.update_attributes!(api: false)
        expect(message: "#{SlackRubyBot.config.user} set api").to respond_with_slack_message(
          'Team data access via the API is off.'
        )
      end
      it 'enables API' do
        team.update_attributes!(api: false)
        expect(message: "#{SlackRubyBot.config.user} set api on").to respond_with_slack_message(
          "Team data access via the API is now on.\n#{SlackSup::Service.api_url}/teams/#{team.id}"
        )
        expect(team.reload.api).to be true
      end
      it 'disables API with set' do
        team.update_attributes!(api: true)
        expect(message: "#{SlackRubyBot.config.user} set api off").to respond_with_slack_message(
          'Team data access via the API is now off.'
        )
        expect(team.reload.api).to be false
      end
      it 'disables API with unset' do
        team.update_attributes!(api: true)
        expect(message: "#{SlackRubyBot.config.user} unset api").to respond_with_slack_message(
          'Team data access via the API is now off.'
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
            "Team data access via the API is on.\nhttp://local.api/teams/#{team.id}"
          )
        end
        it 'shows current value of API off without API URL' do
          team.update_attributes!(api: false)
          expect(message: "#{SlackRubyBot.config.user} set api").to respond_with_slack_message(
            'Team data access via the API is off.'
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
    context 'time' do
      it 'defaults to 9AM' do
        expect(message: "#{SlackRubyBot.config.user} set time").to respond_with_slack_message(
          "Team S'Up is after 9:00 AM."
        )
      end
      it 'shows current value of sup time' do
        team.update_attributes!(sup_time_of_day: 10 * 60 * 60 + 30 * 60)
        expect(message: "#{SlackRubyBot.config.user} set time").to respond_with_slack_message(
          "Team S'Up is after 10:30 AM."
        )
      end
      it 'changes sup time' do
        expect(message: "#{SlackRubyBot.config.user} set time 11:20PM").to respond_with_slack_message(
          "Team S'Up is now after 11:20 PM."
        )
        expect(team.reload.sup_time_of_day).to eq 23 * 60 * 60 + 20 * 60
      end
      it 'errors set on an invalid time' do
        expect(message: "#{SlackRubyBot.config.user} set time foobar").to respond_with_slack_message(
          "Time _foobar_ is invalid. Team S'Up is after 9:00 AM."
        )
      end
    end
    context 'weeks' do
      it 'defaults to one' do
        expect(message: "#{SlackRubyBot.config.user} set weeks").to respond_with_slack_message(
          "Team S'Up is every week."
        )
      end
      it 'shows current value of weeks' do
        team.update_attributes!(sup_every_n_weeks: 3)
        expect(message: "#{SlackRubyBot.config.user} set weeks").to respond_with_slack_message(
          "Team S'Up is every 3 weeks."
        )
      end
      it 'changes weeks' do
        expect(message: "#{SlackRubyBot.config.user} set weeks 2").to respond_with_slack_message(
          "Team S'Up is now every 2 weeks."
        )
        expect(team.reload.sup_every_n_weeks).to eq 2
      end
      it 'errors set on an invalid number of weeks' do
        expect(message: "#{SlackRubyBot.config.user} set weeks foobar").to respond_with_slack_message(
          "Number _foobar_ is invalid. Team S'Up is every week."
        )
      end
    end
    context 'size' do
      it 'defaults to 3' do
        expect(message: "#{SlackRubyBot.config.user} set size").to respond_with_slack_message(
          "Team S'Up connects 3 people."
        )
      end
      it 'shows current value of size' do
        team.update_attributes!(sup_size: 3)
        expect(message: "#{SlackRubyBot.config.user} set size").to respond_with_slack_message(
          "Team S'Up connects 3 people."
        )
      end
      it 'changes size' do
        expect(message: "#{SlackRubyBot.config.user} set size 2").to respond_with_slack_message(
          "Team S'Up now connects 2 people."
        )
        expect(team.reload.sup_size).to eq 2
      end
      it 'errors set on an invalid number of size' do
        expect(message: "#{SlackRubyBot.config.user} set size foobar").to respond_with_slack_message(
          "Number _foobar_ is invalid. Team S'Up connects 3 people."
        )
      end
    end
    context 'timezone' do
      it 'defaults to Eastern Time (US & Canada)' do
        expect(message: "#{SlackRubyBot.config.user} set timezone").to respond_with_slack_message(
          "Team S'Up timezone is #{ActiveSupport::TimeZone.new('Eastern Time (US & Canada)')}."
        )
      end
      it 'shows current value of sup timezone' do
        team.update_attributes!(sup_tz: 'Hawaii')
        expect(message: "#{SlackRubyBot.config.user} set timezone").to respond_with_slack_message(
          "Team S'Up timezone is #{ActiveSupport::TimeZone.new('Hawaii')}."
        )
      end
      it 'changes timezone' do
        expect(message: "#{SlackRubyBot.config.user} set timezone Hawaii").to respond_with_slack_message(
          "Team S'Up timezone is now #{ActiveSupport::TimeZone.new('Hawaii')}."
        )
        expect(team.reload.sup_tz).to eq 'Hawaii'
      end
      it 'errors set on an invalid timezone' do
        expect(message: "#{SlackRubyBot.config.user} set timezone foobar").to respond_with_slack_message(
          "TimeZone _foobar_ is invalid, see https://github.com/rails/rails/blob/5.1.3/activesupport/lib/active_support/values/time_zone.rb#L30 for a list. Team S'Up timezone is currently #{ActiveSupport::TimeZone.new('Eastern Time (US & Canada)')}."
        )
      end
    end
    context 'custom profile team field', vcr: { cassette_name: 'team_profile_get' } do
      it 'is not set by default' do
        expect(message: "#{SlackRubyBot.config.user} set team field").to respond_with_slack_message(
          'Custom profile team field is _not set_.'
        )
      end
      it 'shows current value' do
        team.update_attributes!(team_field_label: 'Artsy Team')
        expect(message: "#{SlackRubyBot.config.user} set team field").to respond_with_slack_message(
          'Custom profile team field is _Artsy Team_.'
        )
      end
      it 'changes value' do
        expect(message: "#{SlackRubyBot.config.user} set team field Artsy Title").to respond_with_slack_message(
          'Custom profile team field is now _Artsy Title_.'
        )
        expect(team.reload.team_field_label).to eq 'Artsy Title'
        expect(team.reload.team_field_label_id).to eq 'Xf6RKY5F2B'
      end
      it 'errors set on an invalid team field' do
        expect(message: "#{SlackRubyBot.config.user} set team field Invalid Field").to respond_with_slack_message(
          'Custom profile team field _Invalid Field_ is invalid. Possible values are _Artsy Title_, _Artsy Team_, _Artsy Subteam_, _Personality Type_, _Instagram_, _Twitter_, _Facebook_, _Website_.'
        )
      end
      it 'unsets' do
        team.update_attributes!(team_field_label: 'Artsy Team')
        expect(message: "#{SlackRubyBot.config.user} unset team field").to respond_with_slack_message(
          'Custom profile team field is now _not set_.'
        )
        expect(team.reload.team_field_label).to be nil
        expect(team.reload.team_field_label_id).to be nil
      end
    end
    context 'invalid' do
      it 'errors set' do
        expect(message: "#{SlackRubyBot.config.user} set invalid on").to respond_with_slack_message(
          'Invalid setting _invalid_, see _help_ for available options.'
        )
      end
      it 'errors unset' do
        expect(message: "#{SlackRubyBot.config.user} unset invalid").to respond_with_slack_message(
          'Invalid setting _invalid_, see _help_ for available options.'
        )
      end
    end
  end
  context 'not admin' do
    context 'api' do
      it 'cannot set api' do
        expect(message: "#{SlackRubyBot.config.user} set api true").to respond_with_slack_message(
          'Only a Slack team admin can turn data access via the API on and off, sorry.'
        )
      end
      it 'can see api value' do
        expect(message: "#{SlackRubyBot.config.user} set api").to respond_with_slack_message(
          "Team data access via the API is on.\n#{team.api_url}"
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
      it 'cannot set time' do
        expect(message: "#{SlackRubyBot.config.user} set time 11:00 AM").to respond_with_slack_message(
          "Team S'Up is after 9:00 AM. Only a Slack team admin can change that, sorry."
        )
      end
      it 'can see time' do
        expect(message: "#{SlackRubyBot.config.user} set time").to respond_with_slack_message(
          "Team S'Up is after 9:00 AM."
        )
      end
      it 'cannot set weeks' do
        expect(message: "#{SlackRubyBot.config.user} set weeks 2").to respond_with_slack_message(
          "Team S'Up is every week. Only a Slack team admin can change that, sorry."
        )
      end
      it 'can see weeks' do
        expect(message: "#{SlackRubyBot.config.user} set weeks").to respond_with_slack_message(
          "Team S'Up is every week."
        )
      end
      it 'cannot set size' do
        expect(message: "#{SlackRubyBot.config.user} set size 2").to respond_with_slack_message(
          "Team S'Up connects 3 people. Only a Slack team admin can change that, sorry."
        )
      end
      it 'can see size' do
        expect(message: "#{SlackRubyBot.config.user} set size").to respond_with_slack_message(
          "Team S'Up connects 3 people."
        )
      end
      it 'cannot set timezone' do
        expect(message: "#{SlackRubyBot.config.user} set tz Hawaii").to respond_with_slack_message(
          "Team S'Up timezone is #{ActiveSupport::TimeZone.new('Eastern Time (US & Canada)')}. Only a Slack team admin can change that, sorry."
        )
      end
      it 'can see timezone' do
        expect(message: "#{SlackRubyBot.config.user} set tz").to respond_with_slack_message(
          "Team S'Up timezone is #{ActiveSupport::TimeZone.new('Eastern Time (US & Canada)')}."
        )
      end
      it 'cannot set custom profile team field' do
        expect(message: "#{SlackRubyBot.config.user} set team field Artsy Team").to respond_with_slack_message(
          'Custom profile team field is _not set_. Only a Slack team admin can change that, sorry.'
        )
      end
      it 'can see custom profile team field' do
        expect(message: "#{SlackRubyBot.config.user} set team field").to respond_with_slack_message(
          'Custom profile team field is _not set_.'
        )
      end
    end
  end
end
