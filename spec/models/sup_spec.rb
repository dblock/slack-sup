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
            "Welcome #{sup.users.asc(:_id).map(&:slack_mention).and}, excited for your first S'Up!"
          )
        end
        it 'two are new' do
          users = sup.users.take(2).sort_by(&:id)
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
  context 'sup!' do
    let(:team) { Fabricate(:team) }
    let!(:user1) { Fabricate(:user, team: team) }
    let!(:user2) { Fabricate(:user, team: team) }
    let!(:user3) { Fabricate(:user, team: team) }
    before do
      allow(team).to receive(:sync!)
    end
    it 'uses default message' do
      expect_any_instance_of(Sup).to receive(:dm!).with(
        text: /Please find a time for a quick 20 minute break on the calendar./
      )
      team.sup!
    end
    it 'includes intro message' do
      expect_any_instance_of(Sup).to receive(:dm!).with(
        text: /Team S'Up connects 3 people on Monday every week. Welcome #{team.users.asc(:_id).map(&:slack_mention).and}, excited for your first S'Up!/
      )
      team.sup!
    end
    it 'uses a custom message' do
      team.update_attributes!(sup_message: 'SUP SUP')
      allow(team).to receive(:sync!)
      expect_any_instance_of(Sup).to receive(:dm!).with(
        text: /SUP SUP/
      )
      team.sup!
    end
    it 'mentions SUP captain' do
      expect_any_instance_of(Sup).to receive(:dm!).with(
        text: /(#{user1.slack_mention}|#{user2.slack_mention}|#{user3.slack_mention}), you're in charge this week to make it happen!/
      )
      expect do
        team.sup!
      end.to change(Sup, :count).by(1)
      sup = team.sups.first
      expect(team.users).to include sup.captain
    end

    context 'find best captain' do
      before do
        allow_any_instance_of(Sup).to receive(:dm!)
        allow_any_instance_of(Round).to receive(:run!)
      end
      it 'picks best captain with one user never been a captain' do
        Fabricate(:sup, captain: user1, created_at: 4.weeks.ago)
        Fabricate(:sup, captain: user1, created_at: 5.weeks.ago)
        Fabricate(:sup, captain: user2, created_at: 6.weeks.ago)
        user4 = Fabricate(:user, team: team)
        sup = Fabricate(:sup, user_ids: [user1.id, user2.id, user4.id])
        sup.sup!
        expect(sup.captain).to eq user4
      end

      it 'picks best captain who last time was captain is older' do
        Fabricate(:sup, captain: user1, created_at: 4.weeks.ago)
        Fabricate(:sup, captain: user1, created_at: 5.weeks.ago)
        Fabricate(:sup, captain: user2, created_at: 6.weeks.ago)
        Fabricate(:sup, captain: user3, created_at: 3.weeks.ago)
        sup = Fabricate(:sup, user_ids: [user1.id, user2.id, user3.id])
        sup.sup!
        expect(sup.captain).to eq user2
      end
    end
  end
end
