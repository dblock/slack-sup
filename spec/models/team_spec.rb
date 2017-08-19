require 'spec_helper'

describe Team do
  context '#find_or_create_from_env!' do
    before do
      ENV['SLACK_API_TOKEN'] = 'token'
    end
    context 'team', vcr: { cassette_name: 'team_info' } do
      it 'creates a team' do
        expect { Team.find_or_create_from_env! }.to change(Team, :count).by(1)
        team = Team.first
        expect(team.team_id).to eq 'T04KB5WQH'
        expect(team.name).to eq 'dblock'
        expect(team.domain).to eq 'dblockdotorg'
        expect(team.token).to eq 'token'
      end
    end
    after do
      ENV.delete 'SLACK_API_TOKEN'
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
    let(:team) { Fabricate(:team, sup_wday: 1, sup_tz: 'Eastern Time (US & Canada)') }
    let(:monday) { DateTime.parse('2017/1/2 3:00 PM EST').utc }
    before do
      Timecop.travel(monday)
    end
    it 'sups' do
      expect(team.sup?).to be true
    end
    it 'in a different timezone' do
      team.update_attributes!(sup_tz: 'Samoa') # Samoa is UTC-11, at 3pm in EST it's Tuesday 10AM
      expect(team.sup?).to be false
    end
  end
  context 'team sup on monday before 9am' do
    let(:team) { Fabricate(:team, sup_wday: 1, sup_tz: 'Eastern Time (US & Canada)') }
    let(:monday) { DateTime.parse('2017/1/2 8:00 AM EST').utc }
    before do
      Timecop.travel(monday)
    end
    it 'does not sup' do
      expect(team.sup?).to be false
    end
  end
  context 'team' do
    let(:team) { Fabricate(:team, sup_wday: Time.now.utc.in_time_zone('Eastern Time (US & Canada)').wday) }
    before do
      allow(team).to receive(:sync!)
    end
    context '#sync!' do
      pending 'adds new users'
      pending 'disables dead users'
      pending 'reactivates users that are back'
    end
    context '#sup!' do
      it 'creates a round for a team' do
        expect do
          team.sup!
        end.to change(Round, :count).by(1)
        round = Round.first
        expect(round.team).to eq(team)
      end
    end
    context '#sup?' do
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
