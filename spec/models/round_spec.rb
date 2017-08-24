require 'spec_helper'

describe Round do
  let(:team) { Fabricate(:team) }
  before do
    allow(team).to receive(:sync!)
    allow_any_instance_of(Sup).to receive(:dm!)
  end
  context '#run' do
    pending 'times out after Round::TIMEOUT'
    context 'with users' do
      let!(:user1) { Fabricate(:user, team: team) }
      let!(:user2) { Fabricate(:user, team: team) }
      let!(:user3) { Fabricate(:user, team: team) }
      it 'generates groups of sup_size size' do
        expect do
          team.sup!
        end.to change(Sup, :count).by(1)
        sup = Sup.first
        expect(sup.users).to eq([user1, user2, user3])
      end
      context 'with sup_size of 2' do
        let!(:user4) { Fabricate(:user, team: team) }
        let!(:user5) { Fabricate(:user, team: team) }
        let!(:user6) { Fabricate(:user, team: team) }
        before do
          team.update_attributes!(sup_size: 2)
        end
        it 'generates pairs' do
          expect do
            team.sup!
          end.to change(Sup, :count).by(3)
          expect(Sup.all.all? { |sup| sup.users.count == 2 })
        end
      end
      context 'opted out' do
        let!(:user4) { Fabricate(:user, team: team) }
        before do
          user3.update_attributes!(opted_in: false)
        end
        it 'excludes opted out users' do
          expect do
            team.sup!
          end.to change(Sup, :count).by(1)
          sup = Sup.first
          expect(sup.users).to eq([user1, user2, user4])
        end
      end
      context 'disabled' do
        let!(:user4) { Fabricate(:user, team: team) }
        before do
          user3.update_attributes!(enabled: false)
        end
        it 'excludes opted out users' do
          expect do
            team.sup!
          end.to change(Sup, :count).by(1)
          sup = Sup.first
          expect(sup.users).to eq([user1, user2, user4])
        end
      end
    end
  end
  context 'a sup round' do
    let!(:user1) { Fabricate(:user, team: team) }
    let!(:user2) { Fabricate(:user, team: team) }
    let!(:user3) { Fabricate(:user, team: team) }
    let!(:round) { team.sup! }
    context '#meeting_already' do
      context 'in the same round' do
        it 'is true for multiple users' do
          expect(round.send(:meeting_already?, [user1, user2])).to be true
        end
        it 'is true for one user' do
          expect(round.send(:meeting_already?, [user1])).to be true
        end
        it 'is false for another user' do
          expect(round.send(:meeting_already?, [Fabricate(:user, team: team)])).to be false
        end
      end
      context 'in a new round immediate after a previous one' do
        let!(:round2) { team.sup! }
        it 'is false for multiple users' do
          expect(round2.send(:meeting_already?, [user1, user2])).to be false
        end
        it 'is false for one user' do
          expect(round2.send(:meeting_already?, [user1])).to be false
        end
        it 'is false for another user' do
          expect(round2.send(:meeting_already?, [Fabricate(:user, team: team)])).to be false
        end
      end
    end
    context '#met_recently?' do
      let!(:round2) { team.sup! }
      it 'is true when users just met' do
        expect(round2.send(:met_recently?, [user1, user2])).to be true
      end
      context 'in not so distant future' do
        before do
          Timecop.travel(Time.now.utc + 1.week)
        end
        it 'is true' do
          expect(round2.send(:met_recently?, [user1, user2])).to be true
        end
      end
      context 'in a distant future' do
        before do
          Timecop.travel(Time.now.utc + team.sup_recency.weeks)
        end
        it 'is false in some distant future' do
          expect(round2.send(:met_recently?, [user1, user2])).to be false
        end
        it 'is true with a sup with both users' do
          Fabricate(:sup, round: round, team: team, users: [user1, user2, Fabricate(:user, team: team)])
          expect(round2.send(:met_recently?, [user1, user2])).to be true
        end
        it 'is false with a sup with one user' do
          Fabricate(:sup, round: round, team: team, users: [Fabricate(:user), user2, Fabricate(:user)])
          expect(round2.send(:met_recently?, [user1, user2])).to be false
        end
      end
    end
    context '#same_team?' do
      it 'is false without custom teams' do
        expect(round.send(:same_team?, [user1, user2, user3])).to be false
      end
      it 'is false when one team set' do
        user1.custom_team_name = 'My Team'
        expect(round.send(:same_team?, [user1, user2, user3])).to be false
      end
      it 'is false when different names' do
        user1.custom_team_name = 'My Team'
        user2.custom_team_name = 'Another Team'
        expect(round.send(:same_team?, [user1, user2])).to be false
        expect(round.send(:same_team?, [user1, user2, user3])).to be false
      end
      it 'is true when same team' do
        user1.custom_team_name = 'My Team'
        user2.custom_team_name = 'My Team'
        expect(round.send(:same_team?, [user1, user2])).to be true
      end
      it 'is true when same team for any two users' do
        user1.custom_team_name = 'My Team'
        user3.custom_team_name = 'My Team'
        expect(round.send(:same_team?, [user1, user2, user3])).to be true
      end
      it 'is true when same team for all 3 users' do
        user1.custom_team_name = 'My Team'
        user2.custom_team_name = 'My Team'
        user3.custom_team_name = 'My Team'
        expect(round.send(:same_team?, [user1, user2, user3])).to be true
      end
    end
    context '#ask?' do
      it 'is false immediately after the round' do
        expect(round.ask?).to be false
      end
      context 'after more than three days' do
        before do
          Timecop.travel(Time.now.utc + 4.days)
        end
        it 'is true' do
          expect(round.ask?).to be true
        end
      end
      context 'after more than three days and already asked' do
        before do
          round.update_attributes!(asked_at: Time.now.utc)
          Timecop.travel(Time.now.utc + 4.days)
        end
        it 'is false' do
          expect(round.ask?).to be false
        end
      end
    end
    context '#ask!' do
      context 'with a sup' do
        let!(:sup) { Fabricate(:sup, team: team, round: round) }
        it 'asks every sup' do
          expect(sup).to receive(:ask!).once
          round.ask!
        end
        it 'updates asked_at' do
          expect(round.asked_at).to be nil
          round.ask!
          expect(round.asked_at).to_not be nil
        end
      end
    end
  end
  context '#dm!' do
    pending 'opens a DM channel with users'
    pending 'sends users a sup message'
  end
end
