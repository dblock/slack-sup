require 'spec_helper'

describe Channel do
  let!(:channel) { Fabricate(:channel) }
  context 'sync!' do
    let(:member_default_attr) do
      {
        is_bot: false,
        deleted: false,
        is_restricted: false,
        is_ultra_restricted: false,
        name: 'Forrest Gump',
        real_name: 'Real Forrest Gump',
        profile: double(email: nil, status: nil, status_text: nil)
      }
    end
    context 'with mixed users' do
      let(:bot_member) { Hashie::Mash.new(member_default_attr.merge(id: 'bot-user', is_bot: true)) }
      let(:deleted_member) { Hashie::Mash.new(member_default_attr.merge(id: 'deleted-user', deleted: true)) }
      let(:restricted_member) { Hashie::Mash.new(member_default_attr.merge(id: 'restricted-user', is_restricted: true)) }
      let(:ultra_restricted_member) { Hashie::Mash.new(member_default_attr.merge(id: 'ult-rest-user', is_ultra_restricted: true)) }
      let(:ooo_member) { Hashie::Mash.new(member_default_attr.merge(id: 'ooo-user', name: 'member-name-on-ooo')) }
      let(:available_member) { Hashie::Mash.new(member_default_attr.merge(id: 'avaialable-user')) }
      let(:members) do
        [bot_member, deleted_member, restricted_member, ultra_restricted_member, ooo_member, available_member]
      end
      before do
        allow_any_instance_of(Slack::Web::Client).to receive(:conversations_members).and_yield(
          Hashie::Mash.new(members: members.map(&:id))
        )
        members.each do |member|
          allow_any_instance_of(Slack::Web::Client).to receive(:users_info)
            .with(user: member.id).and_return(Hashie::Mash.new(user: member))
        end
      end
      it 'adds new users' do
        expect { channel.sync! }.to change(User, :count).by(1)
        new_user = User.last
        expect(new_user.user_id).to eq 'avaialable-user'
        expect(new_user.opted_in).to be true
        expect(new_user.user_name).to eq 'Forrest Gump'
      end
      it 'adds new opted out users' do
        channel.opt_in = false
        expect { channel.sync! }.to change(User, :count).by(1)
        new_user = User.last
        expect(new_user.opted_in).to be false
      end
      it 'disables dead users' do
        available_user = Fabricate(:user, channel: channel, user_id: available_member.id, enabled: true)
        to_be_disabled_users = [deleted_member, restricted_member, ultra_restricted_member, ooo_member].map do |member|
          Fabricate(:user, channel: channel, user_id: member.id, enabled: true)
        end
        expect { channel.sync! }.to_not change(User, :count)
        expect(to_be_disabled_users.map(&:reload).map(&:enabled)).to eq [false] * 4
        expect(available_user.reload.enabled).to be true
      end
      it 'reactivates users that are back' do
        disabled_user = Fabricate(:user, channel: channel, enabled: false, user_id: available_member.id)
        expect { channel.sync! }.to_not change(User, :count)
        expect(disabled_user.reload.enabled).to be true
      end
      pending 'fetches user custom channel information'
    end
    context 'with slack users' do
      let(:members) { [] }
      before do
        allow_any_instance_of(Slack::Web::Client).to receive(:conversations_members).and_yield(Hashie::Mash.new(members: members))
        members.each do |member|
          allow_any_instance_of(Slack::Web::Client).to receive(:users_info)
            .with(user: member).and_return(
              Hashie::Mash.new(user: member_default_attr.merge(id: member))
            )
        end
      end
      context 'with a slack user' do
        let(:members) { ['M1'] }
        it 'creates a new member' do
          expect do
            channel.sync!
          end.to change(User, :count).by(1)
        end
      end
      context 'with two slack users' do
        let(:members) { %w[M1 M2] }
        it 'creates two new users' do
          expect do
            channel.sync!
          end.to change(User, :count).by(2)
          expect(channel.users.count).to eq 2
          expect(channel.users.all?(&:enabled)).to be true
        end
      end
      context 'with an existing user' do
        let(:members) { %w[M1 M2] }
        before do
          Fabricate(:user, channel: channel, user_id: 'M1')
        end
        it 'creates one new member' do
          expect do
            channel.sync!
          end.to change(User, :count).by(1)
          expect(channel.users.count).to eq 2
          expect(channel.users.all?(&:enabled)).to be true
        end
      end
      context 'with an existing user' do
        let(:members) { ['M2'] }
        before do
          Fabricate(:user, channel: channel, user_id: 'M1')
        end
        it 'removes an inactive user' do
          expect do
            channel.sync!
          end.to change(User, :count).by(1)
          expect(channel.users.count).to eq 2
          expect(channel.users.where(user_id: 'M1').first.enabled).to be false
          expect(channel.users.where(user_id: 'M2').first.enabled).to be true
        end
      end
      context 'with an existing disabled user' do
        let(:members) { ['M1'] }
        let!(:member) { Fabricate(:user, channel: channel, user_id: 'M1', enabled: false) }
        it 're-enables it' do
          old_updated_at = member.updated_at
          expect do
            channel.sync!
          end.to_not change(User, :count)
          expect(member.reload.enabled).to be true
          expect(member.updated_at).to_not eq old_updated_at
        end
      end
      context 'with two teams' do
        let(:members) { %w[M1 M2] }
        it 'creates two new members' do
          expect do
            Fabricate(:channel, team: Fabricate(:team)).sync!
            channel.sync!
          end.to change(User, :count).by(4)
          expect(channel.users.count).to eq 2
        end
      end
    end
  end
  context 'channel sup on monday 3pm' do
    let(:tz) { 'Eastern Time (US & Canada)' }
    let(:channel) { Fabricate(:channel, sup_wday: 1, sup_tz: tz) }
    let(:monday) { DateTime.parse('2017/1/2 3:00 PM EST').utc }
    before do
      Timecop.travel(monday)
    end
    context 'sup?' do
      it 'sups' do
        expect(channel.sup?).to be true
      end
      it 'in a different timezone' do
        channel.update_attributes!(sup_tz: 'Samoa') # Samoa is UTC-11, at 3pm in EST it's Tuesday 10AM
        expect(channel.sup?).to be false
      end
    end
    context 'next_sup_at' do
      it 'today' do
        expect(channel.next_sup_at).to eq DateTime.parse('2017/1/2 9:00 AM EST')
      end
    end
  end
  context 'channel sup on monday before 9am' do
    let(:tz) { 'Eastern Time (US & Canada)' }
    let(:channel) { Fabricate(:channel, sup_wday: 1, sup_tz: tz) }
    let(:monday) { DateTime.parse('2017/1/2 8:00 AM EST').utc }
    before do
      Timecop.travel(monday)
    end
    it 'does not sup' do
      expect(channel.sup?).to be false
    end
    context 'next_sup_at' do
      it 'today' do
        expect(channel.next_sup_at).to eq DateTime.parse('2017/1/2 9:00 AM EST')
      end
    end
  end
  context 'with a custom sup_time_of_day' do
    let(:tz) { 'Eastern Time (US & Canada)' }
    let(:channel) { Fabricate(:channel, sup_wday: 1, sup_time_of_day: 7 * 60 * 60, sup_tz: tz) }
    let(:monday) { DateTime.parse('2017/1/2 8:00 AM EST').utc }
    before do
      Timecop.travel(monday)
    end
    context 'sup?' do
      it 'sups' do
        expect(channel.sup?).to be true
      end
    end
    context 'next_sup_at' do
      it 'overdue, one hour ago' do
        expect(channel.next_sup_at).to eq DateTime.parse('2017/1/2 7:00 AM EST')
      end
    end
  end
  context 'channel' do
    let(:tz) { 'Eastern Time (US & Canada)' }
    let(:t_in_time_zone) { Time.now.utc.in_time_zone(tz) }
    let(:wday) { t_in_time_zone.wday }
    let(:beginning_of_day) { t_in_time_zone.beginning_of_day }
    let(:channel) { Fabricate(:channel, sup_wday: wday, sup_time_of_day: 0, sup_tz: tz) }
    context '#sup!' do
      before do
        allow(channel).to receive(:sync!)
      end
      it 'creates a round for a channel' do
        expect do
          channel.sup!
        end.to change(Round, :count).by(1)
        round = Round.first
        expect(round.channel).to eq(channel)
      end
    end
    context '#ask!' do
      it 'works without rounds' do
        expect { channel.ask! }.to_not raise_error
      end
      context 'with a round' do
        before do
          allow(channel).to receive(:sync!)
          channel.sup!
        end
        let(:last_round) { channel.last_round }
        it 'skips last round' do
          allow_any_instance_of(Round).to receive(:ask?).and_return(false)
          expect_any_instance_of(Round).to_not receive(:ask!)
          channel.ask!
        end
        it 'checks against last round' do
          allow_any_instance_of(Round).to receive(:ask?).and_return(true)
          expect_any_instance_of(Round).to receive(:ask!).once
          channel.ask!
        end
      end
    end
    context '#sup?' do
      before do
        allow(channel).to receive(:sync!)
      end
      context 'without rounds' do
        it 'is true' do
          expect(channel.sup?).to be true
        end
      end
      context 'with a round' do
        before do
          channel.sup!
        end
        it 'is false' do
          expect(channel.sup?).to be false
        end
        context 'after less than a week' do
          before do
            Timecop.travel(Time.now.utc + 6.days)
          end
          it 'is false' do
            expect(channel.sup?).to be false
          end
        end
        context 'after more than a week' do
          before do
            Timecop.travel(Time.now.utc + 7.days)
          end
          it 'is true' do
            expect(channel.sup?).to be true
          end
          context 'and another round' do
            before do
              channel.sup!
            end
            it 'is false' do
              expect(channel.sup?).to be false
            end
          end
        end
        context 'with a custom sup_every_n_weeks' do
          before do
            channel.update_attributes!(sup_every_n_weeks: 2)
          end
          context 'after more than a week' do
            before do
              Timecop.travel(Time.now.utc + 7.days)
            end
            it 'is true' do
              expect(channel.sup?).to be false
            end
          end
          context 'after more than two weeks' do
            before do
              Timecop.travel(Time.now.utc + 14.days)
            end
            it 'is true' do
              expect(channel.sup?).to be true
            end
          end
        end
        context 'after more than a week on the wrong day of the week' do
          before do
            Timecop.travel(Time.now.utc + 8.days)
          end
          it 'is false' do
            expect(channel.sup?).to be false
          end
        end
      end
    end
  end
  context '#find_user_by_slack_mention!' do
    let(:user) { Fabricate(:user, channel: channel) }
    it 'finds by slack id' do
      expect(channel.find_user_by_slack_mention!("<@#{user.user_id}>")).to eq user
    end
    it 'finds by username' do
      expect(channel.find_user_by_slack_mention!(user.user_name)).to eq user
    end
    it 'finds by username is case-insensitive' do
      expect(channel.find_user_by_slack_mention!(user.user_name.capitalize)).to eq user
    end
    it 'creates a new user when ID is known' do
      expect do
        channel.find_user_by_slack_mention!('<@nobody>')
      end.to change(User, :count).by(1)
    end
    it 'requires a known user' do
      expect do
        channel.find_user_by_slack_mention!('nobody')
      end.to raise_error SlackSup::Error, "I don't know who nobody is!"
    end
  end
  context '#api_url' do
    it 'sets the API url' do
      expect(channel.api_url).to eq "https://sup2.playplay.io/api/channels/#{channel._id}"
    end
  end
  context '#short_lived_token' do
    let!(:token) { channel.short_lived_token }
    it 'creates a new token every time' do
      expect(channel.short_lived_token).to_not eq token
    end
    it 'validates the token' do
      expect(channel.short_lived_token_valid?(token)).to be true
    end
    it 'does not validate an incorrect token' do
      expect(channel.short_lived_token_valid?('invalid')).to be false
    end
    it 'does not validate an expired token' do
      Timecop.travel(Time.now + 1.hour)
      expect(channel.short_lived_token_valid?(token)).to be false
    end
  end
  context '#parse_slack_mention' do
    it 'valid' do
      expect(Channel.parse_slack_mention('<#channel_id>')).to eq 'channel_id'
    end
    it 'invalid' do
      expect(Channel.parse_slack_mention('invalid')).to be nil
    end
  end
  context '#parse_slack_mention!' do
    it 'valid' do
      expect(Channel.parse_slack_mention!('<#channel_id>')).to eq 'channel_id'
    end
    it 'invalid' do
      expect { Channel.parse_slack_mention!('invalid') }.to raise_error SlackSup::Error, 'Invalid channel mention invalid.'
    end
  end
end
