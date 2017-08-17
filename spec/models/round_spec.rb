require 'spec_helper'

describe Round do
  let(:team) { Fabricate(:team) }
  before do
    allow(team).to receive(:sync!)
    allow_any_instance_of(User).to receive(:introduce_sup!)
    allow_any_instance_of(Sup).to receive(:dm!)
  end
  context '#run' do
    pending 'times out after Round::TIMEOUT'
    context 'with users' do
      let!(:user1) { Fabricate(:user, team: team) }
      let!(:user2) { Fabricate(:user, team: team) }
      let!(:user3) { Fabricate(:user, team: team) }
      it 'generates groups of Round::SIZE size' do
        expect do
          team.sup!
        end.to change(Sup, :count).by(1)
        sup = Sup.first
        expect(sup.users).to eq([user1, user2, user3])
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
  context '#dm!' do
    pending 'opens a DM channel with users'
    pending 'sends users a sup message'
  end
end
