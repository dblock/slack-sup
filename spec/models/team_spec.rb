require 'spec_helper'

describe Team do
  context '#find_create_or_update_channel_by_channel_id!' do
    let(:team) { Fabricate(:team) }
    it 'creates a new channel' do
      expect do
        channel = team.find_create_or_update_channel_by_channel_id!('C123', 'U123')
        expect(channel.channel_id).to eq 'C123'
        expect(channel.inviter_id).to eq 'U123'
      end.to change(Channel, :count).by(1)
    end
    context 'with an existing channel' do
      let!(:channel) { Fabricate(:channel, team: team) }
      it 'reuses an existing channel' do
        expect do
          existing_channel = team.find_create_or_update_channel_by_channel_id!(channel.channel_id, 'U123')
          expect(existing_channel).to eq channel
        end.to_not change(Channel, :count)
      end
    end
  end
  context '#find_create_or_update_user_in_channel_by_slack_id!' do
    let(:team) { Fabricate(:team) }
    it 'creates a new channel and user' do
      expect do
        expect do
          user = team.find_create_or_update_user_in_channel_by_slack_id!('C123', 'U123')
          expect(user.user_id).to eq 'U123'
          expect(user.channel.channel_id).to eq 'C123'
        end.to change(Channel, :count).by(1)
      end.to change(User, :count).by(1)
    end
    context 'with an existing channel' do
      let!(:channel) { Fabricate(:channel, team: team) }
      it 'reuses an existing team and creates a new user' do
        expect do
          expect do
            user = team.find_create_or_update_user_in_channel_by_slack_id!(channel.channel_id, 'U123')
            expect(user.user_id).to eq 'U123'
          end.to_not change(Channel, :count)
        end.to change(User, :count).by(1)
      end
      context 'with an existing team and user' do
        let!(:user) { Fabricate(:user, channel: channel) }
        it 'reuses an existing channel and creates a new user' do
          expect do
            expect do
              found_user = team.find_create_or_update_user_in_channel_by_slack_id!(channel.channel_id, user.user_id)
              expect(found_user.user_id).to eq user.user_id
            end.to_not change(Channel, :count)
          end.to_not change(User, :count)
        end
      end
    end
  end
  context '#join_channel!' do
    let!(:team) { Fabricate(:team) }
    it 'creates a new channel' do
      expect do
        channel = team.join_channel!('C123', 'U123')
        expect(channel).to_not be nil
        expect(channel.channel_id).to eq 'C123'
        expect(channel.inviter_id).to eq 'U123'
        expect(channel.sync).to be true
        expect(channel.last_sync_at).to be nil
      end.to change(Channel, :count).by(1)
    end
    context 'with a previously joined team' do
      let(:channel) { team.join_channel!('C123', 'U123') }
      context 'after leaving a team' do
        before do
          team.leave_channel!(channel.channel_id)
        end
        context 'after rejoining the channel' do
          let!(:rejoined_channel) { team.join_channel!(channel.channel_id, 'U456') }
          it 're-enables channel' do
            rejoined_channel.reload
            expect(rejoined_channel.enabled).to be true
            expect(rejoined_channel.inviter_id).to eq 'U456'
            expect(rejoined_channel.sync).to be true
            expect(rejoined_channel.last_sync_at).to be nil
          end
        end
      end
    end
    context 'with an existing channel' do
      let!(:channel) { Fabricate(:channel, team: team) }
      it 'creates a new channel' do
        expect do
          channel = team.join_channel!('C123', 'U123')
          expect(channel).to_not be nil
          expect(channel.channel_id).to eq 'C123'
          expect(channel.inviter_id).to eq 'U123'
        end.to change(Channel, :count).by(1)
      end
      it 'creates a new channel for a different team' do
        expect do
          team2 = Fabricate(:team)
          channel2 = team2.join_channel!(channel.channel_id, 'U123')
          expect(channel2).to_not be nil
          expect(channel2.team).to eq team2
          expect(channel2.inviter_id).to eq 'U123'
        end.to change(Channel, :count).by(1)
      end
      it 'updates an existing team' do
        expect do
          channel2 = team.join_channel!(channel.channel_id, 'U123')
          expect(channel2).to_not be nil
          expect(channel2).to eq channel
          expect(channel2.team).to eq team
          expect(channel2.inviter_id).to eq 'U123'
        end.to_not change(Channel, :count)
      end
    end
  end
  context '#leave_channel!' do
    let(:team) { Fabricate(:team) }
    it 'ignores a team the bot is not a member of' do
      expect do
        expect(team.leave_channel!('C123')).to be false
      end.to_not change(Channel, :count)
    end
    context 'with an existing team' do
      let!(:channel) { Fabricate(:channel, team: team) }
      context 'after leaving a team' do
        before do
          team.leave_channel!(channel.channel_id)
        end
        it 'disables channel' do
          channel.reload
          expect(channel.enabled).to be false
          expect(channel.sync).to be false
        end
      end
      it 'can leave an existing team twice' do
        expect do
          2.times { expect(team.leave_channel!(channel.channel_id)).to eq channel }
        end.to_not change(Channel, :count)
      end
      it 'does not leave team for the wrong team' do
        team2 = Fabricate(:team)
        expect(team2.leave_channel!(channel.channel_id)).to be false
      end
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
  context '#api_url' do
    let!(:team) { Fabricate(:team) }
    it 'sets the API url' do
      expect(team.api_url).to eq "https://sup.playplay.io/api/teams/#{team._id}"
    end
  end
end
