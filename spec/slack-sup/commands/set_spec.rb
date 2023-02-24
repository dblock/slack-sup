require 'spec_helper'

describe SlackSup::Commands::Set do
  let!(:team) { Fabricate(:team, subscribed: true) }
  let(:app) { SlackSup::Server.new(team: team) }
  let(:client) { app.send(:client) }
  context 'in channel' do
    let!(:channel) { Fabricate(:channel, team: team, channel_id: 'channel') }
    let(:admin) { Fabricate(:user, channel: channel, user_name: 'username', is_admin: true) }
    let(:tz) { ActiveSupport::TimeZone.new('Eastern Time (US & Canada)') }
    let(:tzs) { Time.now.in_time_zone(tz).strftime('%Z') }
    context 'admin' do
      before do
        expect(team).to receive(:find_create_or_update_user_in_channel_by_slack_id!).and_return(admin)
      end
      it 'displays all settings' do
        expect(message: "#{SlackRubyBot.config.user} set").to respond_with_slack_message(
          "Channel S'Up connects groups of max 3 people on Monday after 9:00 AM every week in (GMT-05:00) Eastern Time (US & Canada), taking special care to not pair the same people more frequently than every 12 weeks.\n" \
          "Channel users are _opted in_ by default.\n" \
          "Custom profile team field is _not set_.\n" \
          "Channel data access via the API is on.\n" \
          "#{channel.api_url}"
        )
      end
      context 'opt' do
        it 'shows current value when opted in' do
          channel.update_attributes!(opt_in: true)
          expect(message: "#{SlackRubyBot.config.user} set opt").to respond_with_slack_message(
            'Users are opted in by default.'
          )
        end
        it 'shows current value when opted out' do
          channel.update_attributes!(opt_in: false)
          expect(message: "#{SlackRubyBot.config.user} set opt").to respond_with_slack_message(
            'Users are opted out by default.'
          )
        end
        it 'opts in' do
          channel.update_attributes!(opt_in: false)
          expect(message: "#{SlackRubyBot.config.user} set opt in").to respond_with_slack_message(
            'Users are now opted in by default.'
          )
          expect(channel.reload.opt_in).to be true
        end
        it 'outs out' do
          channel.update_attributes!(opt_in: true)
          expect(message: "#{SlackRubyBot.config.user} set opt out").to respond_with_slack_message(
            'Users are now opted out by default.'
          )
          expect(channel.reload.opt_in).to be false
        end
        it 'fails on an invalid opt value' do
          expect(message: "#{SlackRubyBot.config.user} set opt invalid").to respond_with_slack_message(
            'Invalid value: invalid.'
          )
          expect(channel.reload.opt_in).to be true
        end
      end
      context 'api' do
        it 'shows current value of API on' do
          channel.update_attributes!(api: true)
          expect(message: "#{SlackRubyBot.config.user} set api").to respond_with_slack_message(
            "Channel data access via the API is on.\n#{channel.api_url}"
          )
        end
        it 'shows current value of API off' do
          channel.update_attributes!(api: false)
          expect(message: "#{SlackRubyBot.config.user} set api").to respond_with_slack_message(
            'Channel data access via the API is off.'
          )
        end
        it 'enables API' do
          channel.update_attributes!(api: false)
          expect(message: "#{SlackRubyBot.config.user} set api on").to respond_with_slack_message(
            "Channel data access via the API is now on.\n#{SlackRubyBotServer::Service.api_url}/channels/#{channel.id}"
          )
          expect(channel.reload.api).to be true
        end
        it 'disables API with set' do
          channel.update_attributes!(api: true)
          expect(message: "#{SlackRubyBot.config.user} set api off").to respond_with_slack_message(
            'Channel data access via the API is now off.'
          )
          expect(channel.reload.api).to be false
        end
        context 'with API_URL' do
          before do
            ENV['API_URL'] = 'http://local.api'
          end
          after do
            ENV.delete 'API_URL'
          end
          it 'shows current value of API on with API URL' do
            channel.update_attributes!(api: true)
            expect(message: "#{SlackRubyBot.config.user} set api").to respond_with_slack_message(
              "Channel data access via the API is on.\nhttp://local.api/channels/#{channel.id}"
            )
          end
          it 'shows current value of API off without API URL' do
            channel.update_attributes!(api: false)
            expect(message: "#{SlackRubyBot.config.user} set api").to respond_with_slack_message(
              'Channel data access via the API is off.'
            )
          end
        end
      end
      context 'api token' do
        it 'shows current value of API token' do
          channel.update_attributes!(api_token: 'token', api: true)
          expect(message: "#{SlackRubyBot.config.user} set api token").to respond_with_slack_message(
            "Channel data access via the API is on with an access token `#{channel.api_token}`.\n#{channel.api_url}"
          )
        end
        it "doesn't show current value when API off" do
          channel.update_attributes!(api: false)
          expect(message: "#{SlackRubyBot.config.user} set api token").to respond_with_slack_message(
            'Channel data access via the API is off.'
          )
        end
        it 'rotate api token' do
          expect(SecureRandom).to receive(:hex).and_return('new')
          channel.update_attributes!(api: true, api_token: 'old')
          expect(message: "#{SlackRubyBot.config.user} rotate api token").to respond_with_slack_message(
            "Channel data access via the API is on with a new access token `new`.\n#{channel.api_url}"
          )
          expect(channel.reload.api_token).to eq 'new'
        end
        it 'unsets api token' do
          channel.update_attributes!(api: true, api_token: 'old')
          expect(message: "#{SlackRubyBot.config.user} unset api token").to respond_with_slack_message(
            "Channel data access via the API is now on.\n#{channel.api_url}"
          )
          expect(channel.reload.api_token).to be nil
        end
        context 'with API_URL' do
          before do
            ENV['API_URL'] = 'http://local.api'
          end
          after do
            ENV.delete 'API_URL'
          end
          it 'shows current value of API on with API URL' do
            channel.update_attributes!(api: true)
            expect(message: "#{SlackRubyBot.config.user} set api").to respond_with_slack_message(
              "Channel data access via the API is on.\nhttp://local.api/channels/#{channel.id}"
            )
          end
          it 'shows current value of API off without API URL' do
            channel.update_attributes!(api: false)
            expect(message: "#{SlackRubyBot.config.user} set api").to respond_with_slack_message(
              'Channel data access via the API is off.'
            )
          end
        end
      end
      context 'day' do
        it 'defaults to Monday' do
          expect(message: "#{SlackRubyBot.config.user} set day").to respond_with_slack_message(
            "Channel S'Up is on Monday."
          )
        end
        it 'shows current value of sup day' do
          channel.update_attributes!(sup_wday: 2)
          expect(message: "#{SlackRubyBot.config.user} set day").to respond_with_slack_message(
            "Channel S'Up is on Tuesday."
          )
        end
        it 'changes day' do
          expect(message: "#{SlackRubyBot.config.user} set day friday").to respond_with_slack_message(
            "Channel S'Up is now on Friday."
          )
          expect(channel.reload.sup_wday).to eq 5
        end
        it 'errors set on an invalid day' do
          expect(message: "#{SlackRubyBot.config.user} set day foobar").to respond_with_slack_message(
            "Day _foobar_ is invalid, try _Monday_, _Tuesday_, etc. Channel S'Up is on Monday."
          )
        end
      end
      context 'followup' do
        it 'defaults to Thursday' do
          expect(message: "#{SlackRubyBot.config.user} set followup").to respond_with_slack_message(
            "Channel S'Up followup day is on Thursday."
          )
        end
        it 'shows current value of sup followup' do
          channel.update_attributes!(sup_followup_wday: 2)
          expect(message: "#{SlackRubyBot.config.user} set followup").to respond_with_slack_message(
            "Channel S'Up followup day is on Tuesday."
          )
        end
        it 'changes followup' do
          expect(message: "#{SlackRubyBot.config.user} set followup friday").to respond_with_slack_message(
            "Channel S'Up followup day is now on Friday."
          )
          expect(channel.reload.sup_followup_wday).to eq 5
        end
        it 'errors set on an invalid day' do
          expect(message: "#{SlackRubyBot.config.user} set followup foobar").to respond_with_slack_message(
            "Day _foobar_ is invalid, try _Monday_, _Tuesday_, etc. Channel S'Up followup day is on Thursday."
          )
        end
      end
      context 'time' do
        it 'defaults to 9AM' do
          expect(message: "#{SlackRubyBot.config.user} set time").to respond_with_slack_message(
            "Channel S'Up is after 9:00 AM #{tzs}."
          )
        end
        it 'shows current value of sup time' do
          channel.update_attributes!(sup_time_of_day: 10 * 60 * 60 + 30 * 60)
          expect(message: "#{SlackRubyBot.config.user} set time").to respond_with_slack_message(
            "Channel S'Up is after 10:30 AM #{tzs}."
          )
        end
        it 'changes sup time' do
          expect(message: "#{SlackRubyBot.config.user} set time 11:20PM").to respond_with_slack_message(
            "Channel S'Up is now after 11:20 PM #{tzs}."
          )
          expect(channel.reload.sup_time_of_day).to eq 23 * 60 * 60 + 20 * 60
        end
        it 'errors set on an invalid time' do
          expect(message: "#{SlackRubyBot.config.user} set time foobar").to respond_with_slack_message(
            "Time _foobar_ is invalid. Channel S'Up is after 9:00 AM #{tzs}."
          )
        end
      end
      context 'weeks' do
        it 'defaults to one' do
          expect(message: "#{SlackRubyBot.config.user} set weeks").to respond_with_slack_message(
            "Channel S'Up is every week."
          )
        end
        it 'shows current value of weeks' do
          channel.update_attributes!(sup_every_n_weeks: 3)
          expect(message: "#{SlackRubyBot.config.user} set weeks").to respond_with_slack_message(
            "Channel S'Up is every 3 weeks."
          )
        end
        it 'changes weeks' do
          expect(message: "#{SlackRubyBot.config.user} set weeks 2").to respond_with_slack_message(
            "Channel S'Up is now every 2 weeks."
          )
          expect(channel.reload.sup_every_n_weeks).to eq 2
        end
        it 'errors set on an invalid number of weeks' do
          expect(message: "#{SlackRubyBot.config.user} set weeks foobar").to respond_with_slack_message(
            "Number _foobar_ is invalid. Channel S'Up is every week."
          )
        end
      end
      context 'recency' do
        it 'defaults to one' do
          expect(message: "#{SlackRubyBot.config.user} set recency").to respond_with_slack_message(
            'Taking special care to not pair the same people more than every 12 weeks.'
          )
        end
        it 'shows current value of recency' do
          channel.update_attributes!(sup_recency: 3)
          expect(message: "#{SlackRubyBot.config.user} set recency").to respond_with_slack_message(
            'Taking special care to not pair the same people more than every 3 weeks.'
          )
        end
        it 'changes recency' do
          expect(message: "#{SlackRubyBot.config.user} set recency 2").to respond_with_slack_message(
            'Now taking special care to not pair the same people more than every 2 weeks.'
          )
          expect(channel.reload.sup_recency).to eq 2
        end
        it 'errors set on an invalid number of weeks' do
          expect(message: "#{SlackRubyBot.config.user} set recency foobar").to respond_with_slack_message(
            'Number _foobar_ is invalid. Taking special care to not pair the same people more than every 12 weeks.'
          )
        end
      end
      context 'size' do
        it 'defaults to 3' do
          expect(message: "#{SlackRubyBot.config.user} set size").to respond_with_slack_message(
            "Channel S'Up connects groups of 3 people."
          )
        end
        it 'shows current value of size' do
          channel.update_attributes!(sup_size: 3)
          expect(message: "#{SlackRubyBot.config.user} set size").to respond_with_slack_message(
            "Channel S'Up connects groups of 3 people."
          )
        end
        it 'changes size' do
          expect(message: "#{SlackRubyBot.config.user} set size 2").to respond_with_slack_message(
            "Channel S'Up now connects groups of 2 people."
          )
          expect(channel.reload.sup_size).to eq 2
        end
        it 'errors set on an invalid number of size' do
          expect(message: "#{SlackRubyBot.config.user} set size foobar").to respond_with_slack_message(
            "Number _foobar_ is invalid. Channel S'Up connects groups of 3 people."
          )
        end
      end
      context 'odd' do
        it 'shows current value of odd on' do
          channel.update_attributes!(sup_odd: true)
          expect(message: "#{SlackRubyBot.config.user} set odd").to respond_with_slack_message(
            "Channel S'Up connects groups of max 3 people."
          )
        end
        it 'shows current value of odd off' do
          channel.update_attributes!(sup_odd: false)
          expect(message: "#{SlackRubyBot.config.user} set odd").to respond_with_slack_message(
            "Channel S'Up connects groups of 3 people."
          )
        end
        it 'enables odd' do
          channel.update_attributes!(sup_odd: false)
          expect(message: "#{SlackRubyBot.config.user} set odd true").to respond_with_slack_message(
            "Channel S'Up now connects groups of max 3 people."
          )
          expect(channel.reload.sup_odd).to be true
        end
        it 'disables odd with set' do
          channel.update_attributes!(sup_odd: true)
          expect(message: "#{SlackRubyBot.config.user} set odd false").to respond_with_slack_message(
            "Channel S'Up now connects groups of 3 people."
          )
          expect(channel.reload.sup_odd).to be false
        end
      end
      context 'timezone' do
        it 'defaults to Eastern Time (US & Canada)' do
          expect(message: "#{SlackRubyBot.config.user} set timezone").to respond_with_slack_message(
            "Channel S'Up timezone is #{ActiveSupport::TimeZone.new('Eastern Time (US & Canada)')}."
          )
        end
        it 'shows current value of sup timezone' do
          channel.update_attributes!(sup_tz: 'Hawaii')
          expect(message: "#{SlackRubyBot.config.user} set timezone").to respond_with_slack_message(
            "Channel S'Up timezone is #{ActiveSupport::TimeZone.new('Hawaii')}."
          )
        end
        it 'changes timezone' do
          expect(message: "#{SlackRubyBot.config.user} set timezone Hawaii").to respond_with_slack_message(
            "Channel S'Up timezone is now #{ActiveSupport::TimeZone.new('Hawaii')}."
          )
          expect(channel.reload.sup_tz).to eq 'Hawaii'
        end
        it 'errors set on an invalid timezone' do
          expect(message: "#{SlackRubyBot.config.user} set timezone foobar").to respond_with_slack_message(
            "TimeZone _foobar_ is invalid, see https://github.com/rails/rails/blob/v6.1.7.2/activesupport/lib/active_support/values/time_zone.rb#L30 for a list. Channel S'Up timezone is currently #{ActiveSupport::TimeZone.new('Eastern Time (US & Canada)')}."
          )
        end
      end
      context 'time and time zone together' do
        it 'sets time together with a timezone' do
          expect(message: "#{SlackRubyBot.config.user} set time 10AM Hawaii").to respond_with_slack_message(
            "Channel S'Up is now after 10:00 AM #{Time.now.in_time_zone(ActiveSupport::TimeZone.new('Hawaii')).strftime('%Z')}."
          )
          expect(channel.reload.sup_time_of_day).to eq 10 * 60 * 60
          expect(channel.reload.sup_tz).to eq 'Hawaii'
        end
        it 'sets time together with a timezone' do
          expect(message: "#{SlackRubyBot.config.user} set time 10 AM Hawaii").to respond_with_slack_message(
            "Channel S'Up is now after 10:00 AM #{Time.now.in_time_zone(ActiveSupport::TimeZone.new('Hawaii')).strftime('%Z')}."
          )
          expect(channel.reload.sup_time_of_day).to eq 10 * 60 * 60
          expect(channel.reload.sup_tz).to eq 'Hawaii'
        end
        it 'sets time together with a timezone' do
          expect(message: "#{SlackRubyBot.config.user} set time 10:00 AM Pacific Time (US & Canada)").to respond_with_slack_message(
            "Channel S'Up is now after 10:00 AM #{Time.now.in_time_zone(ActiveSupport::TimeZone.new('America/Los_Angeles')).strftime('%Z')}."
          )
          expect(channel.reload.sup_time_of_day).to eq 10 * 60 * 60
          expect(channel.reload.sup_tz).to eq 'Pacific Time (US & Canada)'
        end
      end
      context 'custom profile team field', vcr: { cassette_name: 'team_profile_get' } do
        it 'is not set by default' do
          expect(message: "#{SlackRubyBot.config.user} set team field").to respond_with_slack_message(
            'Custom profile team field is _not set_.'
          )
        end
        it 'shows current value' do
          channel.update_attributes!(team_field_label: 'Artsy Team')
          expect(message: "#{SlackRubyBot.config.user} set team field").to respond_with_slack_message(
            'Custom profile team field is _Artsy Team_.'
          )
        end
        it 'changes value' do
          expect(message: "#{SlackRubyBot.config.user} set team field Artsy Title").to respond_with_slack_message(
            'Custom profile team field is now _Artsy Title_.'
          )
          expect(channel.reload.team_field_label).to eq 'Artsy Title'
          expect(channel.reload.team_field_label_id).to eq 'Xf6RKY5F2B'
        end
        it 'errors set on an invalid team field' do
          expect(message: "#{SlackRubyBot.config.user} set team field Invalid Field").to respond_with_slack_message(
            'Custom profile team field _Invalid Field_ is invalid. Possible values are _Artsy Title_, _Artsy Team_, _Artsy Subteam_, _Personality Type_, _Instagram_, _Twitter_, _Facebook_, _Website_.'
          )
        end
        it 'unsets' do
          channel.update_attributes!(team_field_label: 'Artsy Team')
          expect(message: "#{SlackRubyBot.config.user} unset team field").to respond_with_slack_message(
            'Custom profile team field is now _not set_.'
          )
          expect(channel.reload.team_field_label).to be nil
          expect(channel.reload.team_field_label_id).to be nil
        end
      end
      context 'custom sup message' do
        it 'is not set by default' do
          expect(message: "#{SlackRubyBot.config.user} set message").to respond_with_slack_message(
            "Using the default S'Up message. _#{Sup::PLEASE_SUP_MESSAGE}_"
          )
        end
        it 'shows current value' do
          channel.update_attributes!(sup_message: 'Please meet.')
          expect(message: "#{SlackRubyBot.config.user} set message").to respond_with_slack_message(
            "Using a custom S'Up message. _Please meet._"
          )
        end
        it 'changes value' do
          expect(message: "#{SlackRubyBot.config.user} set message Hello world!").to respond_with_slack_message(
            "Now using a custom S'Up message. _Hello world!_"
          )
          expect(channel.reload.sup_message).to eq 'Hello world!'
        end
        it 'unsets' do
          channel.update_attributes!(sup_message: 'Updated')
          expect(message: "#{SlackRubyBot.config.user} unset message").to respond_with_slack_message(
            "Now using the default S'Up message. _#{Sup::PLEASE_SUP_MESSAGE}_"
          )
          expect(channel.reload.sup_message).to be nil
        end
      end
      context 'invalid' do
        it 'errors set' do
          expect(message: "#{SlackRubyBot.config.user} set invalid on").to respond_with_slack_message(
            'Invalid channel setting _invalid_, see _help_ for available options.'
          )
        end
        it 'errors unset' do
          expect(message: "#{SlackRubyBot.config.user} unset invalid").to respond_with_slack_message(
            'Invalid channel setting _invalid_, see _help_ for available options.'
          )
        end
        it 'errors rotate' do
          expect(message: "#{SlackRubyBot.config.user} rotate invalid").to respond_with_slack_message(
            'Invalid channel setting _invalid_, see _help_ for available options.'
          )
        end
      end
      context 'sync' do
        let!(:requester) { Fabricate(:user, channel: channel, user_id: 'user') }
        it 'shows next sync' do
          channel.update_attributes!(sync: true)
          expect(message: "#{SlackRubyBot.config.user} set sync").to respond_with_slack_message(
            'Users will sync in the next hour.'
          )
        end
        it 'shows last sync' do
          channel.update_attributes!(sync: false)
          expect(message: "#{SlackRubyBot.config.user} set sync").to respond_with_slack_message(
            "Users will sync before the next round. #{channel.next_sup_at_text}"
          )
        end
        it 'shows last sync that had user updates' do
          Timecop.travel(Time.now.utc + 1.minute)
          channel.update_attributes!(last_sync_at: Time.now.utc)
          Fabricate(:user, channel: channel)
          expect(message: "#{SlackRubyBot.config.user} set sync").to respond_with_slack_message(
            "Last users sync was less than 1 second ago. 1 user updated. Users will sync before the next round. #{channel.next_sup_at_text}"
          )
        end
        it 'shows last sync that had no user updates' do
          Fabricate(:user, channel: channel)
          Timecop.travel(Time.now.utc + 1.minute)
          channel.update_attributes!(last_sync_at: Time.now.utc)
          expect(message: "#{SlackRubyBot.config.user} set sync").to respond_with_slack_message(
            "Last users sync was less than 1 second ago. No users updated. Users will sync before the next round. #{channel.next_sup_at_text}"
          )
        end
        it 'shows last sync that had multiple users updates' do
          Timecop.travel(Time.now.utc + 1.minute)
          channel.update_attributes!(last_sync_at: Time.now.utc)
          2.times { Fabricate(:user, channel: channel) }
          expect(message: "#{SlackRubyBot.config.user} set sync").to respond_with_slack_message(
            "Last users sync was less than 1 second ago. 2 users updated. Users will sync before the next round. #{channel.next_sup_at_text}"
          )
        end
        it 'sets sync' do
          channel.update_attributes!(sup_odd: false)
          expect(message: "#{SlackRubyBot.config.user} set sync now").to respond_with_slack_message(
            'Users will sync in the next hour. Come back and run `set sync` or `stats` in a bit.'
          )
          expect(channel.reload.sync).to be true
        end
        it 'errors on invalid sync value' do
          channel.update_attributes!(sync: false)
          expect(message: "#{SlackRubyBot.config.user} set sync foobar").to respond_with_slack_message(
            'The option _foobar_ is invalid. Use `now` to schedule a user sync in the next hour.'
          )
          expect(channel.reload.sync).to be false
        end
      end
    end
    context 'not admin' do
      context 'api' do
        it 'cannot set opt' do
          expect(message: "#{SlackRubyBot.config.user} set opt out").to respond_with_slack_message(
            "Users are opted in by default. Only <@#{channel.inviter_id}> or a Slack team admin can change that, sorry."
          )
        end
        it 'cannot set api' do
          expect(message: "#{SlackRubyBot.config.user} set api true").to respond_with_slack_message(
            "Channel data access via the API is on. Only <@#{channel.inviter_id}> or a Slack team admin can change that, sorry."
          )
        end
        it 'can see api value' do
          expect(message: "#{SlackRubyBot.config.user} set api").to respond_with_slack_message(
            "Channel data access via the API is on.\n#{channel.api_url}"
          )
        end
        it 'does not show current value of API token' do
          channel.update_attributes!(api_token: 'token', api: true)
          expect(message: "#{SlackRubyBot.config.user} set api token").to respond_with_slack_message(
            "Channel data access via the API is on with an access token visible to admins.\n#{channel.api_url}"
          )
        end
        it 'rotate api token' do
          channel.update_attributes!(api: true, api_token: 'old')
          expect(message: "#{SlackRubyBot.config.user} rotate api token").to respond_with_slack_message(
            "Channel data access via the API is on with an access token visible to admins. Only <@#{channel.inviter_id}> or a Slack team admin can rotate it, sorry."
          )
          expect(channel.reload.api_token).to eq 'old'
        end
        it 'unsets api token' do
          channel.update_attributes!(api: true, api_token: 'old')
          expect(message: "#{SlackRubyBot.config.user} unset api token").to respond_with_slack_message(
            "Channel data access via the API is on with an access token visible to admins. Only <@#{channel.inviter_id}> or a Slack team admin can unset it, sorry."
          )
          expect(channel.reload.api_token).to eq 'old'
        end
        it 'cannot set day' do
          expect(message: "#{SlackRubyBot.config.user} set day tuesday").to respond_with_slack_message(
            "Channel S'Up is on Monday. Only <@#{channel.inviter_id}> or a Slack team admin can change that, sorry."
          )
        end
        it 'can see sup day' do
          expect(message: "#{SlackRubyBot.config.user} set day").to respond_with_slack_message(
            "Channel S'Up is on Monday."
          )
        end
        it 'cannot set time' do
          expect(message: "#{SlackRubyBot.config.user} set time 11:00 AM").to respond_with_slack_message(
            "Channel S'Up is after 9:00 AM #{tzs}. Only <@#{channel.inviter_id}> or a Slack team admin can change that, sorry."
          )
        end
        it 'can see time' do
          expect(message: "#{SlackRubyBot.config.user} set time").to respond_with_slack_message(
            "Channel S'Up is after 9:00 AM #{tzs}."
          )
        end
        it 'cannot set weeks' do
          expect(message: "#{SlackRubyBot.config.user} set weeks 2").to respond_with_slack_message(
            "Channel S'Up is every week. Only <@#{channel.inviter_id}> or a Slack team admin can change that, sorry."
          )
        end
        it 'can see weeks' do
          expect(message: "#{SlackRubyBot.config.user} set weeks").to respond_with_slack_message(
            "Channel S'Up is every week."
          )
        end
        it 'cannot set followup day' do
          expect(message: "#{SlackRubyBot.config.user} set followup 2").to respond_with_slack_message(
            "Channel S'Up followup day is on Thursday. Only <@#{channel.inviter_id}> or a Slack team admin can change that, sorry."
          )
        end
        it 'can see followup day' do
          expect(message: "#{SlackRubyBot.config.user} set followup").to respond_with_slack_message(
            "Channel S'Up followup day is on Thursday."
          )
        end
        it 'cannot set recency' do
          expect(message: "#{SlackRubyBot.config.user} set recency 2").to respond_with_slack_message(
            "Taking special care to not pair the same people more than every 12 weeks. Only <@#{channel.inviter_id}> or a Slack team admin can change that, sorry."
          )
        end
        it 'can see recency' do
          expect(message: "#{SlackRubyBot.config.user} set recency").to respond_with_slack_message(
            'Taking special care to not pair the same people more than every 12 weeks.'
          )
        end
        it 'cannot set size' do
          expect(message: "#{SlackRubyBot.config.user} set size 2").to respond_with_slack_message(
            "Channel S'Up connects groups of 3 people. Only <@#{channel.inviter_id}> or a Slack team admin can change that, sorry."
          )
        end
        it 'can see size' do
          expect(message: "#{SlackRubyBot.config.user} set size").to respond_with_slack_message(
            "Channel S'Up connects groups of 3 people."
          )
        end
        it 'cannot set timezone' do
          expect(message: "#{SlackRubyBot.config.user} set tz Hawaii").to respond_with_slack_message(
            "Channel S'Up timezone is #{ActiveSupport::TimeZone.new('Eastern Time (US & Canada)')}. Only <@#{channel.inviter_id}> or a Slack team admin can change that, sorry."
          )
        end
        it 'can see timezone' do
          expect(message: "#{SlackRubyBot.config.user} set tz").to respond_with_slack_message(
            "Channel S'Up timezone is #{ActiveSupport::TimeZone.new('Eastern Time (US & Canada)')}."
          )
        end
        it 'cannot set custom profile team field' do
          expect(message: "#{SlackRubyBot.config.user} set team field Artsy Team").to respond_with_slack_message(
            "Custom profile team field is _not set_. Only <@#{channel.inviter_id}> or a Slack team admin can change that, sorry."
          )
        end
        it 'can see custom profile team field' do
          expect(message: "#{SlackRubyBot.config.user} set team field").to respond_with_slack_message(
            'Custom profile team field is _not set_.'
          )
        end
        it 'cannot set message' do
          expect(message: "#{SlackRubyBot.config.user} set message Custom message.").to respond_with_slack_message(
            "Using the default S'Up message. _#{Sup::PLEASE_SUP_MESSAGE}_ Only <@#{channel.inviter_id}> or a Slack team admin can change that, sorry."
          )
        end
        it 'can see custom sup message' do
          expect(message: "#{SlackRubyBot.config.user} set message").to respond_with_slack_message(
            "Using the default S'Up message. _#{Sup::PLEASE_SUP_MESSAGE}_"
          )
        end
        it 'can see sync info' do
          expect(message: "#{SlackRubyBot.config.user} set sync").to respond_with_slack_message(
            "Users will sync before the next round. #{channel.next_sup_at_text}"
          )
        end
        it 'can see exact sync date' do
          channel.update_attributes!(sync: true)
          expect(message: "#{SlackRubyBot.config.user} set sync").to respond_with_slack_message(
            'Users will sync in the next hour.'
          )
        end
        it 'cannot set sync now' do
          expect(message: "#{SlackRubyBot.config.user} set sync now").to respond_with_slack_message(
            "Users will sync before the next round. #{channel.next_sup_at_text} Only <@#{channel.inviter_id}> or a Slack team admin can manually sync, sorry."
          )
        end
      end
    end
  end
  context 'DM' do
    context 'admin' do
      context 'set' do
        it 'displays all settings' do
          expect(message: "#{SlackRubyBot.config.user} set", channel: 'DM', user: team.activated_user_id).to respond_with_slack_message(
            "S'Up is not enabled in any channels.\n" \
            "Team data access via the API is on.\n" \
            "#{team.api_url}"
          )
        end
        context 'with a channel' do
          let!(:channel) { Fabricate(:channel, team: team) }
          it 'displays all settings' do
            expect(message: "#{SlackRubyBot.config.user} set", channel: 'DM', user: team.activated_user_id).to respond_with_slack_message(
              "S'Up is enabled in #{channel.slack_mention}.\n" \
              "Team data access via the API is on.\n" \
              "#{team.api_url}"
            )
          end
        end
        context 'with multiple channels' do
          let!(:channel1) { Fabricate(:channel, team: team) }
          let!(:channel2) { Fabricate(:channel, team: team) }
          it 'displays all settings' do
            expect(message: "#{SlackRubyBot.config.user} set", channel: 'DM', user: team.activated_user_id).to respond_with_slack_message(
              "S'Up is enabled in 2 channels (#{channel1.slack_mention} and #{channel2.slack_mention}).\n" \
              "Team data access via the API is on.\n" \
              "#{team.api_url}"
            )
          end
        end
      end
      context 'api' do
        it 'shows current value of API on' do
          team.update_attributes!(api: true)
          expect(message: "#{SlackRubyBot.config.user} set api", channel: 'DM', user: team.activated_user_id).to respond_with_slack_message(
            "Team data access via the API is on.\n#{team.api_url}"
          )
        end
        it 'shows current value of API off' do
          team.update_attributes!(api: false)
          expect(message: "#{SlackRubyBot.config.user} set api", channel: 'DM', user: team.activated_user_id).to respond_with_slack_message(
            'Team data access via the API is off.'
          )
        end
        it 'enables API' do
          team.update_attributes!(api: false)
          expect(message: "#{SlackRubyBot.config.user} set api on", channel: 'DM', user: team.activated_user_id).to respond_with_slack_message(
            "Team data access via the API is now on.\n#{SlackRubyBotServer::Service.api_url}/teams/#{team.id}"
          )
          expect(team.reload.api).to be true
        end
        it 'disables API with set' do
          team.update_attributes!(api: true)
          expect(message: "#{SlackRubyBot.config.user} set api off", channel: 'DM', user: team.activated_user_id).to respond_with_slack_message(
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
            expect(message: "#{SlackRubyBot.config.user} set api", channel: 'DM', user: team.activated_user_id).to respond_with_slack_message(
              "Team data access via the API is on.\nhttp://local.api/teams/#{team.id}"
            )
          end
          it 'shows current value of API off without API URL' do
            team.update_attributes!(api: false)
            expect(message: "#{SlackRubyBot.config.user} set api", channel: 'DM', user: team.activated_user_id).to respond_with_slack_message(
              'Team data access via the API is off.'
            )
          end
        end
      end
      context 'api token' do
        it 'shows current value of API token' do
          team.update_attributes!(api_token: 'token', api: true)
          expect(message: "#{SlackRubyBot.config.user} set api token", channel: 'DM', user: team.activated_user_id).to respond_with_slack_message(
            "Team data access via the API is on with an access token `#{team.api_token}`.\n#{team.api_url}"
          )
        end
        it "doesn't show current value when API off" do
          team.update_attributes!(api: false)
          expect(message: "#{SlackRubyBot.config.user} set api token", channel: 'DM', user: team.activated_user_id).to respond_with_slack_message(
            'Team data access via the API is off.'
          )
        end
        it 'rotate api token' do
          expect(SecureRandom).to receive(:hex).and_return('new')
          team.update_attributes!(api: true, api_token: 'old')
          expect(message: "#{SlackRubyBot.config.user} rotate api token", channel: 'DM', user: team.activated_user_id).to respond_with_slack_message(
            "Team data access via the API is on with a new access token `new`.\n#{team.api_url}"
          )
          expect(team.reload.api_token).to eq 'new'
        end
        it 'unsets api token' do
          team.update_attributes!(api: true, api_token: 'old')
          expect(message: "#{SlackRubyBot.config.user} unset api token", channel: 'DM', user: team.activated_user_id).to respond_with_slack_message(
            "Team data access via the API is now on.\n#{team.api_url}"
          )
          expect(team.reload.api_token).to be nil
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
            expect(message: "#{SlackRubyBot.config.user} set api", channel: 'DM', user: team.activated_user_id).to respond_with_slack_message(
              "Team data access via the API is on.\nhttp://local.api/teams/#{team.id}"
            )
          end
          it 'shows current value of API off without API URL' do
            team.update_attributes!(api: false)
            expect(message: "#{SlackRubyBot.config.user} set api", channel: 'DM', user: team.activated_user_id).to respond_with_slack_message(
              'Team data access via the API is off.'
            )
          end
        end
      end
      context 'invalid' do
        it 'errors set' do
          expect(message: "#{SlackRubyBot.config.user} set invalid on", channel: 'DM').to respond_with_slack_message(
            'Invalid global setting _invalid_, see _help_ for available options.'
          )
        end
        it 'errors unset' do
          expect(message: "#{SlackRubyBot.config.user} unset invalid", channel: 'DM').to respond_with_slack_message(
            'Invalid global setting _invalid_, see _help_ for available options.'
          )
        end
        it 'errors rotate' do
          expect(message: "#{SlackRubyBot.config.user} rotate invalid", channel: 'DM').to respond_with_slack_message(
            'Invalid global setting _invalid_, see _help_ for available options.'
          )
        end
      end
    end
    context 'not an admin' do
      before do
        allow_any_instance_of(Slack::Web::Client).to receive(:users_info).with(
          user: 'user'
        ).and_return(Hashie::Mash.new(
                       user: {
                         is_admin: false,
                         is_owner: false
                       }
                     ))
      end
      context 'set' do
        it 'displays all settings' do
          expect(message: "#{SlackRubyBot.config.user} set", channel: 'DM').to respond_with_slack_message(
            "S'Up is not enabled in any channels.\n" \
            "Team data access via the API is on.\n" \
            "#{team.api_url}"
          )
        end
        context 'with a channel' do
          let!(:channel) { Fabricate(:channel, team: team) }
          it 'displays all settings' do
            expect(message: "#{SlackRubyBot.config.user} set", channel: 'DM').to respond_with_slack_message(
              "S'Up is enabled in #{channel.slack_mention}.\n" \
              "Team data access via the API is on.\n" \
              "#{team.api_url}"
            )
          end
        end
        context 'with multiple channels' do
          let!(:channel1) { Fabricate(:channel, team: team) }
          let!(:channel2) { Fabricate(:channel, team: team) }
          it 'displays all settings' do
            expect(message: "#{SlackRubyBot.config.user} set", channel: 'DM').to respond_with_slack_message(
              "S'Up is enabled in 2 channels (#{channel1.slack_mention} and #{channel2.slack_mention}).\n" \
              "Team data access via the API is on.\n" \
              "#{team.api_url}"
            )
          end
        end
      end
      context 'api' do
        it 'shows current value of API on' do
          team.update_attributes!(api: true)
          expect(message: "#{SlackRubyBot.config.user} set api", channel: 'DM').to respond_with_slack_message(
            "Team data access via the API is on.\n#{team.api_url}"
          )
        end
        it 'shows current value of API off' do
          team.update_attributes!(api: false)
          expect(message: "#{SlackRubyBot.config.user} set api", channel: 'DM').to respond_with_slack_message(
            'Team data access via the API is off.'
          )
        end
        it 'cannot enable API' do
          team.update_attributes!(api: false)
          expect(message: "#{SlackRubyBot.config.user} set api on", channel: 'DM').to respond_with_slack_message(
            "Team data access via the API is off. Only <@#{team.activated_user_id}> or a Slack team admin can change that, sorry."
          )
          expect(team.reload.api).to be false
        end
        it 'disables API with set' do
          team.update_attributes!(api: true)
          expect(message: "#{SlackRubyBot.config.user} set api off", channel: 'DM').to respond_with_slack_message(
            "Team data access via the API is on. Only <@#{team.activated_user_id}> or a Slack team admin can change that, sorry."
          )
          expect(team.reload.api).to be true
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
            expect(message: "#{SlackRubyBot.config.user} set api", channel: 'DM').to respond_with_slack_message(
              "Team data access via the API is on.\nhttp://local.api/teams/#{team.id}"
            )
          end
          it 'shows current value of API off without API URL' do
            team.update_attributes!(api: false)
            expect(message: "#{SlackRubyBot.config.user} set api", channel: 'DM').to respond_with_slack_message(
              'Team data access via the API is off.'
            )
          end
        end
      end
      context 'api token' do
        it 'shows current value of API token' do
          team.update_attributes!(api_token: 'token', api: true)
          expect(message: "#{SlackRubyBot.config.user} set api token", channel: 'DM').to respond_with_slack_message(
            "Team data access via the API is on with an access token visible to admins.\n#{team.api_url}"
          )
        end
        it "doesn't show current value when API off" do
          team.update_attributes!(api: false)
          expect(message: "#{SlackRubyBot.config.user} set api token", channel: 'DM').to respond_with_slack_message(
            'Team data access via the API is off.'
          )
        end
        it 'cannot rotate api token' do
          expect(SecureRandom).to_not receive(:hex)
          team.update_attributes!(api: true, api_token: 'old')
          expect(message: "#{SlackRubyBot.config.user} rotate api token", channel: 'DM').to respond_with_slack_message(
            "Team data access via the API is on with an access token visible to admins. Only <@#{team.activated_user_id}> or a Slack team admin can rotate it, sorry."
          )
          expect(team.reload.api_token).to eq 'old'
        end
        it 'cannot unset api token' do
          team.update_attributes!(api: true, api_token: 'old')
          expect(message: "#{SlackRubyBot.config.user} unset api token", channel: 'DM').to respond_with_slack_message(
            "Team data access via the API is on with an access token visible to admins. Only <@#{team.activated_user_id}> or a Slack team admin can unset it, sorry."
          )
          expect(team.reload.api_token).to eq 'old'
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
            expect(message: "#{SlackRubyBot.config.user} set api", channel: 'DM').to respond_with_slack_message(
              "Team data access via the API is on.\nhttp://local.api/teams/#{team.id}"
            )
          end
          it 'shows current value of API off without API URL' do
            team.update_attributes!(api: false)
            expect(message: "#{SlackRubyBot.config.user} set api", channel: 'DM').to respond_with_slack_message(
              'Team data access via the API is off.'
            )
          end
        end
      end
    end
  end
end
