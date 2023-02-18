require 'spec_helper'

describe Channel do
  let!(:channel) { Fabricate(:channel) }
  context 'sync!' do
    context 'with slack users' do
      let(:members) { [] }
      let(:is_bot) { false }
      before do
        allow_any_instance_of(Slack::Web::Client).to receive(:paginate).with(
          :conversations_members, hash_including({})
        ).and_return([
                       Hashie::Mash.new(members: [
                                          members
                                        ])
                     ])

        members.each do |member|
          allow_any_instance_of(Slack::Web::Client).to receive(:users_info).with(
            user: member
          ).and_return(
            Hashie::Mash.new(user: {
                               profile: {
                                 email: Faker::Internet.email,
                                 real_name: Faker::Name.name
                               },
                               is_bot: is_bot
                             })
          )
        end
      end
      context 'with a slack user' do
        let(:members) { ['M1'] }
        it 'creates a new member' do
          expect do
            channel.sync!
          end.to change(Member, :count).by(1)
        end
      end
      context 'with two slack users' do
        let(:members) { %w[M1 M2] }
        it 'creates two new members' do
          expect do
            channel.sync!
          end.to change(Member, :count).by(2)
          expect(channel.members.count).to eq 2
          expect(channel.members.all?(&:enabled)).to be true
        end
      end
      context 'with an existing user' do
        let(:members) { %w[M1 M2] }
        before do
          Fabricate(:member, channel: channel, user_id: 'M1')
        end
        it 'creates one new member' do
          expect do
            channel.sync!
          end.to change(Member, :count).by(1)
          expect(channel.members.count).to eq 2
          expect(channel.members.all?(&:enabled)).to be true
        end
      end
      context 'with an existing member' do
        let(:members) { ['M2'] }
        before do
          Fabricate(:member, channel: channel, user_id: 'M1')
        end
        it 'removes an inactive member' do
          expect do
            channel.sync!
          end.to change(Member, :count).by(1)
          expect(channel.members.count).to eq 2
          expect(channel.members.where(user_id: 'M1').first.enabled).to be false
          expect(channel.members.where(user_id: 'M2').first.enabled).to be true
        end
      end
      context 'with an existing disabled member' do
        let(:members) { ['M1'] }
        let!(:member) { Fabricate(:member, channel: channel, user_id: 'M1', enabled: false, real_name: 'Bob Marley') }
        it 'updates member fields but does not re-enable it' do
          expect do
            channel.sync!
          end.to_not change(Member, :count)
          expect(member.reload.real_name).to_not eq 'Bob Marley'
          expect(member.reload.enabled).to be false
        end
      end
      context 'with two teams' do
        let(:members) { %w[M1 M2] }
        it 'creates two new members' do
          expect do
            Fabricate(:channel, team: Fabricate(:team)).sync!
            channel.sync!
          end.to change(Member, :count).by(4)
          expect(channel.members.count).to eq 2
        end
      end
      context 'with a bot user' do
        let(:members) { ['M1'] }
        let(:is_bot) { true }
        it 'does not create a new member' do
          expect do
            channel.sync!
          end.to_not change(Member, :count)
        end
      end
    end
  end
end
