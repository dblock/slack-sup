require 'spec_helper'

describe User do
  context '#find_by_slack_mention!' do
    let(:user) { Fabricate(:user) }
    it 'finds by slack id' do
      expect(User.find_by_slack_mention!(user.team, "<@#{user.user_id}>")).to eq user
    end
    it 'finds by username' do
      expect(User.find_by_slack_mention!(user.team, user.user_name)).to eq user
    end
    it 'finds by username is case-insensitive' do
      expect(User.find_by_slack_mention!(user.team, user.user_name.capitalize)).to eq user
    end
    it 'requires a known user' do
      expect do
        User.find_by_slack_mention!(user.team, '<@nobody>')
      end.to raise_error SlackSup::Error, "I don't know who <@nobody> is!"
    end
  end
  context '#find_create_or_update_by_slack_id!', vcr: { cassette_name: 'user_info' } do
    let!(:team) { Fabricate(:team) }
    let(:client) { SlackRubyBot::Client.new }
    before do
      client.owner = team
    end
    context 'without a user' do
      it 'creates a user' do
        expect do
          user = User.find_create_or_update_by_slack_id!(client, 'U42')
          expect(user).to_not be_nil
          expect(user.user_id).to eq 'U42'
          expect(user.user_name).to eq 'username'
        end.to change(User, :count).by(1)
      end
      it 'creates an opted in user' do
        user = User.find_create_or_update_by_slack_id!(client, 'U42')
        expect(user).to_not be_nil
        expect(user.opted_in).to be true
      end
      it 'creates an opted out user' do
        team.opt_in = false
        user = User.find_create_or_update_by_slack_id!(client, 'U42')
        expect(user).to_not be_nil
        expect(user.opted_in).to be false
      end
    end
    context 'with a user' do
      let!(:user) { Fabricate(:user, team: team) }
      it 'creates another user' do
        expect do
          User.find_create_or_update_by_slack_id!(client, 'U42')
        end.to change(User, :count).by(1)
      end
      it 'updates the username of the existing user' do
        expect do
          User.find_create_or_update_by_slack_id!(client, user.user_id)
        end.to_not change(User, :count)
        expect(user.reload.user_name).to eq 'username'
      end
    end
  end
  context '#update_custom_profile' do
    let(:user) { Fabricate(:user) }
    before do
      user.team.team_field_label_id = 'Xf6QJY0DS8'
    end
    it 'fetches custom profile information from slack', vcr: { cassette_name: 'user_profile_get' } do
      user.update_custom_profile
      expect(user.custom_team_name).to eq 'Engineering'
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
end
