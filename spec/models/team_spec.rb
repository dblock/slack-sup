require 'spec_helper'

describe Team do
  context '#join_channel!' do
    let(:team) { Fabricate(:team) }
    it 'creates a new channel' do
      expect do
        channel = team.join_channel!('C123', 'U123')
        expect(channel).to_not be nil
        expect(channel.channel_id).to eq 'C123'
        expect(channel.inviter_id).to eq 'U123'
        expect(channel.sync).to be true
        expect(channel.last_sync_at).to be nil
      end.to change(Channel, :count).by(1)
    end
    context 'with a previously joined channel' do
      let(:channel) { team.join_channel!('C123', 'U123') }
      context 'after leaving a channel' do
        before do
          team.leave_channel!(channel.channel_id)
        end
        context 'after rejoining the channel' do
          let!(:rejoined_channel) { team.join_channel!(channel.channel_id, 'U456') }
          it 're-enables channel' do
            rejoined_channel.reload
            expect(rejoined_channel.enabled).to be true
            expect(rejoined_channel.inviter_id).to eq 'U456'
            expect(rejoined_channel.sync).to be true
            expect(rejoined_channel.last_sync_at).to be nil
          end
        end
      end
    end
    context 'with an existing channel' do
      let!(:channel) { Fabricate(:channel, team: team) }
      it 'creates a new channel' do
        expect do
          channel = team.join_channel!('C123', 'U123')
          expect(channel).to_not be nil
          expect(channel.channel_id).to eq 'C123'
          expect(channel.inviter_id).to eq 'U123'
        end.to change(Channel, :count).by(1)
      end
      it 'creates a new channel for a different team' do
        expect do
          team2 = Fabricate(:team)
          channel2 = team2.join_channel!(channel.channel_id, 'U123')
          expect(channel2).to_not be nil
          expect(channel2.channel_id).to eq channel.channel_id
          expect(channel2.inviter_id).to eq 'U123'
        end.to change(Channel, :count).by(1)
      end
      it 'updates an existing channel' do
        expect do
          channel2 = team.join_channel!(channel.channel_id, 'U123')
          expect(channel2).to_not be nil
          expect(channel2).to eq channel
          expect(channel2.channel_id).to eq channel.channel_id
          expect(channel2.inviter_id).to eq 'U123'
        end.to_not change(Channel, :count)
      end
    end
  end
  context '#leave_channel!' do
    let(:team) { Fabricate(:team) }
    it 'ignores a channel the bot is not a member of' do
      expect do
        expect(team.leave_channel!('C123')).to be false
      end.to_not change(Channel, :count)
    end
    context 'with an existing channel' do
      let!(:channel) { Fabricate(:channel, team: team) }
      context 'after leaving a channel' do
        before do
          team.leave_channel!(channel.channel_id)
        end
        it 'disables channel' do
          channel.reload
          expect(channel.enabled).to be false
          expect(channel.sync).to be false
        end
      end
      it 'can leave an existing channel twice' do
        expect do
          expect(team.leave_channel!(channel.channel_id)).to eq channel
          expect(team.leave_channel!(channel.channel_id)).to eq channel
        end.to_not change(Channel, :count)
      end
      it 'does not leave channel for the wrong team' do
        team2 = Fabricate(:team)
        expect(team2.leave_channel!(channel.channel_id)).to be false
      end
    end
  end
  context '#short_lived_token' do
    let(:team) { Fabricate(:team) }
    it 'create a new token every time' do
      token1 = team.short_lived_token
      Timecop.travel(Time.now + 1.second)
      token2 = team.short_lived_token
      expect(token1).to_not eq token2
    end
    it 'create a token that is valid for 1 minute' do
      token = team.short_lived_token
      expect(team.short_lived_token_valid?(token)).to be true
      Timecop.travel(Time.now.utc + 30.minutes)
      expect(team.short_lived_token_valid?(token)).to be false
    end
  end
  context '#purge!' do
    let!(:active_team) { Fabricate(:team) }
    let!(:inactive_team) { Fabricate(:team, active: false) }
    let!(:inactive_team_a_week_ago) { Fabricate(:team, updated_at: 1.week.ago, active: false) }
    let!(:inactive_team_three_weeks_ago) { Fabricate(:team, updated_at: 3.weeks.ago, active: false) }
    let!(:inactive_team_a_month_ago) { Fabricate(:team, updated_at: 1.month.ago, active: false) }
    it 'destroys teams inactive for two weeks' do
      expect do
        Team.purge!
      end.to change(Team, :count).by(-2)
      expect(Team.find(active_team.id)).to eq active_team
      expect(Team.find(inactive_team.id)).to eq inactive_team
      expect(Team.find(inactive_team_a_week_ago.id)).to eq inactive_team_a_week_ago
      expect(Team.find(inactive_team_three_weeks_ago.id)).to be nil
      expect(Team.find(inactive_team_a_month_ago.id)).to be nil
    end
  end
  context '#asleep?' do
    context 'default' do
      let(:team) { Fabricate(:team, created_at: Time.now.utc) }
      it 'false' do
        expect(team.asleep?).to be false
      end
    end
    context 'team created three weeks ago' do
      let(:team) { Fabricate(:team, created_at: 3.weeks.ago) }
      it 'is asleep' do
        expect(team.asleep?).to be true
      end
    end
    context 'team created two weeks ago and subscribed' do
      let(:team) { Fabricate(:team, created_at: 2.weeks.ago, subscribed: true) }
      before do
        allow(team).to receive(:inform_subscribed_changed!)
        team.update_attributes!(subscribed: true)
      end
      it 'is not asleep' do
        expect(team.asleep?).to be false
      end
    end
    context 'team created over three weeks ago' do
      let(:team) { Fabricate(:team, created_at: 3.weeks.ago - 1.day) }
      it 'is asleep' do
        expect(team.asleep?).to be true
      end
    end
    context 'team created over two weeks ago and subscribed' do
      let(:team) { Fabricate(:team, created_at: 2.weeks.ago - 1.day, subscribed: true) }
      it 'is not asleep' do
        expect(team.asleep?).to be false
      end
    end
  end
  context 'team sup on monday 3pm' do
    let(:tz) { 'Eastern Time (US & Canada)' }
    let(:team) { Fabricate(:team, sup_wday: 1, sup_tz: tz) }
    let(:monday) { DateTime.parse('2017/1/2 3:00 PM EST').utc }
    before do
      Timecop.travel(monday)
    end
    context 'sup?' do
      it 'sups' do
        expect(team.sup?).to be true
      end
      it 'in a different timezone' do
        team.update_attributes!(sup_tz: 'Samoa') # Samoa is UTC-11, at 3pm in EST it's Tuesday 10AM
        expect(team.sup?).to be false
      end
    end
    context 'next_sup_at' do
      it 'today' do
        expect(team.next_sup_at).to eq DateTime.parse('2017/1/2 9:00 AM EST')
      end
    end
  end
  context 'team sup on monday before 9am' do
    let(:tz) { 'Eastern Time (US & Canada)' }
    let(:team) { Fabricate(:team, sup_wday: 1, sup_tz: tz) }
    let(:monday) { DateTime.parse('2017/1/2 8:00 AM EST').utc }
    before do
      Timecop.travel(monday)
    end
    it 'does not sup' do
      expect(team.sup?).to be false
    end
    context 'next_sup_at' do
      it 'today' do
        expect(team.next_sup_at).to eq DateTime.parse('2017/1/2 9:00 AM EST')
      end
    end
  end
  context 'with a custom sup_time_of_day' do
    let(:tz) { 'Eastern Time (US & Canada)' }
    let(:team) { Fabricate(:team, sup_wday: 1, sup_time_of_day: 7 * 60 * 60, sup_tz: tz) }
    let(:monday) { DateTime.parse('2017/1/2 8:00 AM EST').utc }
    before do
      Timecop.travel(monday)
    end
    context 'sup?' do
      it 'sups' do
        expect(team.sup?).to be true
      end
    end
    context 'next_sup_at' do
      it 'overdue, one hour ago' do
        expect(team.next_sup_at).to eq DateTime.parse('2017/1/2 7:00 AM EST')
      end
    end
  end
  context 'team' do
    let(:tz) { 'Eastern Time (US & Canada)' }
    let(:t_in_time_zone) { Time.now.utc.in_time_zone(tz) }
    let(:wday) { t_in_time_zone.wday }
    let(:beginning_of_day) { t_in_time_zone.beginning_of_day }
    let(:team) { Fabricate(:team, sup_wday: wday, sup_time_of_day: 7 * 60 * 60 + 1, sup_tz: tz) }
    context '#sync!' do
      let(:member_default_attr) do
        {
          id: 'member-id',
          is_bot: false,
          deleted: false,
          is_restricted: false,
          is_ultra_restricted: false,
          name: 'Forrest Gump',
          real_name: 'Real Forrest Gump',
          profile: double(email: nil, status: nil, status_text: nil)
        }
      end
      let(:bot_member) { double(member_default_attr.merge(id: 'bot-user', is_bot: true)) }
      let(:deleted_member) { double(member_default_attr.merge(id: 'deleted-user', deleted: true)) }
      let(:restricted_member) { double(member_default_attr.merge(id: 'restricted-user', is_restricted: true)) }
      let(:ultra_restricted_member) { double(member_default_attr.merge(id: 'ult-rest-user', is_ultra_restricted: true)) }
      let(:ooo_member) { double(member_default_attr.merge(id: 'ooo-user', name: 'member-name-on-ooo')) }
      let(:available_member) { double(member_default_attr) }
      let(:members) do
        [bot_member, deleted_member, restricted_member, ultra_restricted_member, ooo_member, available_member]
      end
      before do
        allow_any_instance_of(Slack::Web::Client).to receive(:paginate).and_return([double(members: members)])
      end
      it 'adds new users' do
        expect { team.sync! }.to change(User, :count).by(1)
        new_user = User.last
        expect(new_user.user_id).to eq 'member-id'
        expect(new_user.opted_in).to be true
        expect(new_user.user_name).to eq 'Forrest Gump'
      end
      it 'adds new opted out users' do
        team.opt_in = false
        expect { team.sync! }.to change(User, :count).by(1)
        new_user = User.last
        expect(new_user.opted_in).to be false
      end
      it 'disables dead users' do
        available_user = Fabricate(:user, team: team, user_id: available_member.id, enabled: true)
        to_be_disabled_users = [deleted_member, restricted_member, ultra_restricted_member, ooo_member].map do |member|
          Fabricate(:user, team: team, user_id: member.id, enabled: true)
        end
        expect { team.sync! }.to change(User, :count).by(0)
        expect(to_be_disabled_users.map(&:reload).map(&:enabled)).to eq [false] * 4
        expect(available_user.reload.enabled).to be true
      end
      it 'reactivates users that are back' do
        disabled_user = Fabricate(:user, team: team, enabled: false, user_id: available_member.id)
        expect { team.sync! }.to change(User, :count).by(0)
        expect(disabled_user.reload.enabled).to be true
      end
      pending 'fetches user custom team information'
    end
    context '#sup!' do
      before do
        allow(team).to receive(:sync!)
      end
      it 'creates a round for a team' do
        expect do
          team.sup!
        end.to change(Round, :count).by(1)
        round = Round.first
        expect(round.team).to eq(team)
      end
    end
    context '#ask!' do
      it 'works without rounds' do
        expect { team.ask! }.to_not raise_error
      end
      context 'with a round' do
        before do
          allow(team).to receive(:sync!)
          team.sup!
        end
        let(:last_round) { team.last_round }
        it 'skips last round' do
          allow_any_instance_of(Round).to receive(:ask?).and_return(false)
          expect_any_instance_of(Round).to_not receive(:ask!)
          team.ask!
        end
        it 'checks against last round' do
          allow_any_instance_of(Round).to receive(:ask?).and_return(true)
          expect_any_instance_of(Round).to receive(:ask!).once
          team.ask!
        end
      end
    end
    context '#sup?' do
      before do
        allow(team).to receive(:sync!)
      end
      context 'without rounds' do
        it 'is true' do
          expect(team.sup?).to be true
        end
      end
      context 'with a round' do
        before do
          team.sup!
        end
        it 'is false' do
          expect(team.sup?).to be false
        end
        context 'after less than a week' do
          before do
            Timecop.travel(Time.now.utc + 6.days)
          end
          it 'is false' do
            expect(team.sup?).to be false
          end
        end
        context 'after more than a week' do
          before do
            Timecop.travel(Time.now.utc + 7.days)
          end
          it 'is true' do
            expect(team.sup?).to be true
          end
          context 'and another round' do
            before do
              team.sup!
            end
            it 'is false' do
              expect(team.sup?).to be false
            end
          end
        end
        context 'with a custom sup_every_n_weeks' do
          before do
            team.update_attributes!(sup_every_n_weeks: 2)
          end
          context 'after more than a week' do
            before do
              Timecop.travel(Time.now.utc + 7.days)
            end
            it 'is true' do
              expect(team.sup?).to be false
            end
          end
          context 'after more than two weeks' do
            before do
              Timecop.travel(Time.now.utc + 14.days)
            end
            it 'is true' do
              expect(team.sup?).to be true
            end
          end
        end
        context 'after more than a week on the wrong day of the week' do
          before do
            Timecop.travel(Time.now.utc + 8.days)
          end
          it 'is false' do
            expect(team.sup?).to be false
          end
        end
      end
    end
  end
end
