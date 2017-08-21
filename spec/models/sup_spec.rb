require 'spec_helper'

describe Sup do
  context 'a sup' do
    let(:sup) { Fabricate(:sup) }
    it 'asks for outcome' do
      message = Sup::ASK_WHO_SUP_MESSAGE.dup
      message[:attachments][0][:callback_id] = sup.id.to_s
      expect(sup).to receive(:dm!).with(message)
      sup.ask!
    end
  end
  context 'a round' do
    let(:team) { Fabricate(:team) }
    let!(:user1) { Fabricate(:user, team: team) }
    let!(:user2) { Fabricate(:user, team: team) }
    let!(:user3) { Fabricate(:user, team: team) }
    before do
      allow(team).to receive(:sync!)
      allow_any_instance_of(Sup).to receive(:dm!)
    end
    let!(:round) { team.sup! }
    it 'generates sups' do
      expect(round.sups.count).to eq 1
    end
  end
end
