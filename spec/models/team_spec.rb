require 'spec_helper'

describe Team do
  context 'days of week' do
    {
      DateTime.parse('2017/1/2 3:00 PM EST').utc => { wday: Date::TUESDAY, followup_wday: Date::THURSDAY },
      DateTime.parse('2017/1/3 3:00 PM EST').utc => { wday: Date::WEDNESDAY, followup_wday: Date::FRIDAY },
      DateTime.parse('2017/1/4 3:00 PM EST').utc => { wday: Date::THURSDAY, followup_wday: Date::TUESDAY },
      DateTime.parse('2017/1/5 3:00 PM EST').utc => { wday: Date::FRIDAY, followup_wday: Date::TUESDAY },
      DateTime.parse('2017/1/6 3:00 PM EST').utc => { wday: Date::MONDAY, followup_wday: Date::THURSDAY },
      DateTime.parse('2017/1/7 3:00 PM EST').utc => { wday: Date::MONDAY, followup_wday: Date::THURSDAY },
      DateTime.parse('2017/1/8 3:00 PM EST').utc => { wday: Date::MONDAY, followup_wday: Date::THURSDAY }
    }.each_pair do |dt, expectations|
      context "created on #{Date::DAYNAMES[dt.wday]}" do
        before do
          Timecop.travel(dt)
        end

        let(:team) { Fabricate(:team) }

        it "sets sup to #{Date::DAYNAMES[expectations[:wday]]}" do
          expect(team.sup_wday).to eq expectations[:wday]
        end

        it "sets reminder to #{Date::DAYNAMES[expectations[:followup_wday]]}" do
          expect(team.sup_followup_wday).to eq expectations[:followup_wday]
        end
      end
    end
  end

  context 'team_admins' do
    let(:team) { Fabricate(:team) }

    it 'has no activated users' do
      expect(team.team_admins).to eq([])
    end

    context 'with an activated user' do
      let!(:user) { Fabricate(:user, team:) }

      before do
        team.update_attributes!(activated_user_id: user.user_id)
      end

      it 'has an admin' do
        expect(team.team_admins).to eq([user])
        expect(team.team_admins_slack_mentions).to eq(user.slack_mention)
      end

      context 'with another admin' do
        let!(:another) { Fabricate(:user, team:, is_admin: true) }

        it 'has two admins' do
          expect(team.team_admins.to_a.sort).to eq([user, another].sort)
          expect(team.team_admins_slack_mentions).to eq([user.slack_mention, another.slack_mention].or)
        end
      end

      context 'with another owner' do
        let!(:another) { Fabricate(:user, team:, is_owner: true) }

        it 'has two admins' do
          expect(team.team_admins.to_a.sort).to eq([user, another].sort)
          expect(team.team_admins_slack_mentions).to eq([user.slack_mention, another.slack_mention].or)
        end
      end

      context 'with an admin in another team' do
        let!(:another) { Fabricate(:user, team: Fabricate(:team), is_admin: true) }

        it 'has one admin' do
          expect(team.team_admins).to eq([user])
          expect(team.team_admins_slack_mentions).to eq(user.slack_mention)
        end
      end
    end
  end

  describe '#short_lived_token' do
    let(:team) { Fabricate(:team) }

    it 'create a new token every time' do
      token1 = team.short_lived_token
      Timecop.travel(Time.now + 1.second)
      token2 = team.short_lived_token
      expect(token1).not_to eq token2
    end

    it 'create a token that is valid for 1 minute' do
      token = team.short_lived_token
      expect(team.short_lived_token_valid?(token)).to be true
      Timecop.travel(Time.now.utc + 30.minutes)
      expect(team.short_lived_token_valid?(token)).to be false
    end
  end

  describe '#purge!' do
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
      expect(Team.find(inactive_team_three_weeks_ago.id)).to be_nil
      expect(Team.find(inactive_team_a_month_ago.id)).to be_nil
    end
  end

  describe '#asleep?' do
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
    let(:team) { Fabricate(:team, sup_wday: Date::MONDAY, sup_tz: tz) }
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
    let(:team) { Fabricate(:team, sup_wday: Date::MONDAY, sup_tz: tz) }
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
    let(:team) { Fabricate(:team, sup_wday: Date::MONDAY, sup_time_of_day: 7 * 60 * 60, sup_tz: tz) }
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
    let(:team) { Fabricate(:team, sup_wday: wday, sup_time_of_day: 0, sup_tz: tz) }

    describe '#sync!' do
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
        allow_any_instance_of(Slack::Web::Client).to receive(:paginate).and_return([double(members:)])
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
        available_user = Fabricate(:user, team:, user_id: available_member.id, enabled: true)
        to_be_disabled_users = [deleted_member, restricted_member, ultra_restricted_member, ooo_member].map do |member|
          Fabricate(:user, team:, user_id: member.id, enabled: true)
        end
        expect { team.sync! }.not_to change(User, :count)
        expect(to_be_disabled_users.map(&:reload).map(&:enabled)).to eq [false] * 4
        expect(available_user.reload.enabled).to be true
      end

      it 'enables users with the same ID present in multiple teams' do
        team2 = Fabricate(:team)
        Fabricate(:user, team: team2, user_id: available_member.id, enabled: true)
        available_user = Fabricate(:user, team:, user_id: available_member.id, enabled: true)
        to_be_disabled_users = [deleted_member, restricted_member, ultra_restricted_member, ooo_member].map do |member|
          Fabricate(:user, team:, user_id: member.id, enabled: true)
        end
        expect { team.sync! }.not_to change(User, :count)
        expect(to_be_disabled_users.map(&:reload).map(&:enabled)).to eq [false] * 4
        expect(available_user.reload.enabled).to be true
      end

      it 'reactivates users that are back' do
        disabled_user = Fabricate(:user, team:, enabled: false, user_id: available_member.id)
        expect { team.sync! }.not_to change(User, :count)
        expect(disabled_user.reload.enabled).to be true
      end

      pending 'fetches user custom team information'
    end

    describe '#sup!' do
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

    describe '#ask!' do
      it 'works without rounds' do
        expect { team.ask! }.not_to raise_error
      end

      context 'with a round' do
        before do
          allow(team).to receive(:sync!)
          team.sup!
        end

        let(:last_round) { team.last_round }

        it 'skips last round' do
          allow_any_instance_of(Round).to receive(:ask?).and_return(false)
          expect_any_instance_of(Round).not_to receive(:ask!)
          team.ask!
        end

        it 'checks against last round' do
          allow_any_instance_of(Round).to receive(:ask?).and_return(true)
          expect_any_instance_of(Round).to receive(:ask!).once
          team.ask!
        end
      end
    end

    describe '#sup?' do
      before do
        Timecop.travel(beginning_of_day + (8 * 60 * 60))
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

  describe '#export' do
    let(:team) { Fabricate(:team) }

    include_context 'uses temp dir'
    before do
      allow(team).to receive(:sync!)
      allow(team).to receive(:inform!)
      team.sup!
      team.export!(tmp)
    end

    %w[team rounds sups stats users].each do |csv|
      it "creates #{csv}.csv" do
        expect(File.exist?(File.join(tmp, "#{csv}.csv"))).to be true
      end
    end
    it 'creates rounds subfolders' do
      expect(Dir.exist?(File.join(tmp, 'rounds'))).to be true
      expect(File.exist?(File.join(tmp, 'rounds', team.rounds.first.ran_at.strftime('%F'), 'round.csv'))).to be true
    end

    context 'team.csv' do
      let(:csv) { CSV.read(File.join(tmp, 'team.csv'), headers: true) }

      it 'generates csv' do
        expect(csv.headers).to eq(
          %w[
            id
            team_id
            name
            domain
            active
            subscribed
            subscribed_at
            created_at
            updated_at
            sup_wday
            sup_followup_wday
            sup_day
            sup_tz
            sup_time_of_day
            sup_time_of_day_s
            sup_every_n_weeks
            sup_size
          ]
        )
        row = csv[0]
        expect(row['team_id']).to eq team.team_id
      end
    end
  end

  describe '#export_zip!' do
    let(:team) { Fabricate(:team) }

    include_context 'uses temp dir'
    before do
      allow(team).to receive(:sync!)
      allow(team).to receive(:inform!)
      team.sup!
      team.export!(tmp)
    end

    context 'zip' do
      let!(:zip) { team.export_zip!(tmp) }

      it 'exists' do
        expect(File.exist?(zip)).to be true
        expect(File.size(zip)).not_to eq 0
      end
    end
  end
end
