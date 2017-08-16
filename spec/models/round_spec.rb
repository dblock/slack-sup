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
  context '#meeting_already' do
    pending 'is false for meetings in a different round'
    pending 'is true for meetings in the same round'
  end
end
