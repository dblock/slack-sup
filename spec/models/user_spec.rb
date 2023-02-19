require 'spec_helper'

describe User do
  context '#sync!', vcr: { cassette_name: 'user_info' } do
    let(:channel) { Fabricate(:channel) }
    let(:user) { Fabricate(:user, channel: channel) }
    it 'updates user fields' do
      user.sync!
      expect(user.sync).to be false
      expect(user.last_sync_at).to_not be nil
      expect(user.is_organizer).to be false
      expect(user.is_admin).to be true
      expect(user.is_owner).to be true
      expect(user.user_name).to eq 'username'
      expect(user.real_name).to eq 'Real Name'
      expect(user.email).to eq 'user@example.com'
    end
    context 'with team field label' do
      before do
        # avoid validation that would attempt to fetch profile
        channel.set(team_field_label_id: 'Xf6QJY0DS8')
      end
      it 'fetches custom profile information from slack', vcr: { cassette_name: 'user_profile_get' } do
        user.reload.sync!
        expect(user.custom_team_name).to eq 'Engineering'
      end
    end
  end
  context '#find_or_create_user!' do
    let!(:channel) { Fabricate(:channel) }
    context 'without a user' do
      context 'with opted out channel by default' do
        before do
          channel.update_attributes!(opt_in: false)
        end
        it 'creates an opted out user' do
          user = channel.find_or_create_user!('user_id')
          expect(user).to_not be_nil
          expect(user.opted_in).to be false
        end
      end
      it 'creates a user' do
        expect do
          user = channel.find_or_create_user!('user_id')
          expect(user).to_not be_nil
          expect(user.user_id).to eq 'user_id'
          expect(user.sync).to be true
        end.to change(User, :count).by(1)
      end
    end
    context 'with an existing user' do
      let!(:user) { Fabricate(:user, channel: channel) }
      it 'creates another user' do
        expect do
          channel.find_or_create_user!('user_id')
        end.to change(User, :count).by(1)
      end
      it 'returns the existing user' do
        expect do
          channel.find_or_create_user!(user.user_id)
        end.to_not change(User, :count)
      end
    end
  end
  context '#last_captain_at' do
    let(:user) { Fabricate(:user) }
    it 'retuns nil when user has never been a captain' do
      expect(user.last_captain_at).to be_nil
    end
    context 'with a sup' do
      let!(:sup) { Fabricate(:sup, captain: user, created_at: 2.weeks.ago) }
      it 'returns last time user was captain' do
        expect(user.last_captain_at).to eq sup.reload.created_at
      end
      it 'returns nol for another user' do
        expect(Fabricate(:user).last_captain_at).to be nil
      end
    end
    context 'with multiple sups' do
      let!(:sup1) { Fabricate(:sup, captain: user, created_at: 2.weeks.ago) }
      let!(:sup2) { Fabricate(:sup, captain: user, created_at: 3.weeks.ago) }
      it 'returns most recent sup' do
        expect(user.last_captain_at).to eq sup1.reload.created_at
      end
    end
  end
  context '#suppable_user?' do
    let(:member_default_attr) do
      {
        id: 'id',
        is_bot: false,
        deleted: false,
        is_restricted: false,
        is_ultra_restricted: false,
        name: 'Forrest Gump',
        real_name: 'Real Forrest Gump',
        profile: double(email: nil, status: nil, status_text: nil)
      }
    end
    it 'is_bot' do
      expect(User.suppable_user?(Hashie::Mash.new(member_default_attr.merge(is_bot: true)))).to be false
    end
    it 'deleted' do
      expect(User.suppable_user?(Hashie::Mash.new(member_default_attr.merge(deleted: true)))).to be false
    end
    it 'restricted' do
      expect(User.suppable_user?(Hashie::Mash.new(member_default_attr.merge(is_restricted: true)))).to be false
    end
    it 'ultra_restricted' do
      expect(User.suppable_user?(Hashie::Mash.new(member_default_attr.merge(is_ultra_restricted: true)))).to be false
    end
    it 'ooo' do
      expect(User.suppable_user?(Hashie::Mash.new(member_default_attr.merge(name: 'member-name-on-ooo')))).to be false
    end
    it 'default' do
      expect(User.suppable_user?(Hashie::Mash.new(member_default_attr))).to be true
    end
  end
end
