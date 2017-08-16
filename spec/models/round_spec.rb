require 'spec_helper'

describe Round do
  let(:team) { Fabricate(:team) }
  context '#for' do
    it 'creates a round for a team' do
      expect(Round).to receive(:create!).with(team: team)
      Round.for(team)
    end
  end
  context '#run' do
    it 'runs clean without users' do
      expect { Round.for(team) }.to_not raise_error
    end
    pending 'times out after Round::TIMEOUT'
    context 'with users' do
      let!(:user1) { Fabricate(:user, team: team) }
      let!(:user2) { Fabricate(:user, team: team) }
      let!(:user3) { Fabricate(:user, team: team) }
      it 'generates groups of Round::SIZE size' do
        expect do
          Round.for(team)
        end.to change(Sup, :count).by(1)
        sup = Sup.first
        expect(sup.users).to eq([user1, user2, user3])
      end
    end
  end
  context 'a sup round' do
    let!(:user1) { Fabricate(:user, team: team) }
    let!(:user2) { Fabricate(:user, team: team) }
    let!(:user3) { Fabricate(:user, team: team) }
    let(:sup) { Fabricate(:sup, team: team, round: round, users: [user1, user2]) }
    let!(:round) { Round.for(team) }
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
        let!(:round2) { Round.for(team) }
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
    context '#met_recently' do
      it 'is true when users just met' do
        expect(round.send(:met_recently?, [user1, user2])).to be true
      end
      it 'is false in some distant future' do
        Timecop.travel(Time.now + 4.months)
        expect(round.send(:met_recently?, [user1, user2])).to be false
      end
    end
  end
end
