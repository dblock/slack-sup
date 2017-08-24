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
    context 'sup' do
      let(:sup) { round.sups.first }
      context 'intro message' do
        it 'everyone is new' do
          sup.users.each { |u| u.update_attributes!(introduced_sup_at: nil) }
          expect(sup.send(:intro_message)).to eq(
            'The most valuable relationships are not made of 2 people, they’re made of 3. ' \
            "Team S'Up connects 3 people on Monday every week. " \
            "Welcome #{sup.users.map(&:slack_mention).and}, excited for your first S'Up!"
          )
        end
        it 'two are new' do
          users = sup.users.take(2)
          users.each { |u| u.update_attributes!(introduced_sup_at: nil) }
          expect(sup.send(:intro_message)).to eq(
            'The most valuable relationships are not made of 2 people, they’re made of 3. ' \
            "Team S'Up connects 3 people on Monday every week. " \
            "Welcome #{users.map(&:slack_mention).and}, excited for your first S'Up!"
          )
        end
        it 'one is new' do
          sup.users.first.update_attributes!(introduced_sup_at: nil)
          expect(sup.send(:intro_message)).to eq(
            'The most valuable relationships are not made of 2 people, they’re made of 3. ' \
            "Team S'Up connects 3 people on Monday every week. " \
            "Welcome #{sup.users.first.slack_mention}, excited for your first S'Up!"
          )
        end
        it 'one is new and sup_size is not 3' do
          sup.team.update_attributes!(sup_size: 2)
          sup.users.first.update_attributes!(introduced_sup_at: nil)
          expect(sup.send(:intro_message)).to eq(
            "Team S'Up connects 2 people on Monday every week. " \
            "Welcome #{sup.users.first.slack_mention}, excited for your first S'Up!"
          )
        end
        it 'nobody is new' do
          expect(sup.send(:intro_message)).to be nil
        end
      end
    end
  end
end
