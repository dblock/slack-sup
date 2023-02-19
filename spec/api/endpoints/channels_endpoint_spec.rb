require 'spec_helper'

describe Api::Endpoints::ChannelsEndpoint do
  include Api::Test::EndpointTest

  let!(:team) { Fabricate(:team, api: true) }

  before do
    @cursor_params = { team_id: team.id.to_s }
  end

  it_behaves_like 'a cursor api', Channel

  context 'channel' do
    let(:existing_channel) { Fabricate(:channel, team: team) }
    it 'returns a channel' do
      channel = client.channel(id: existing_channel.id)
      expect(channel.id).to eq existing_channel.id.to_s
      expect(channel.channel_id).to eq existing_channel.channel_id
      expect(channel._links.self._url).to eq "http://example.org/api/channels/#{existing_channel.id}"
    end
  end

  context 'channels' do
    let!(:channel_1) { Fabricate(:channel, team: team) }
    let!(:channel_2) { Fabricate(:channel, team: team) }
    it 'returns channels' do
      channels = client.channels(team_id: team.id)
      expect(channels.map(&:id).sort).to eq [channel_1, channel_2].map(&:id).map(&:to_s).sort
    end
    context 'with team api off' do
      before do
        team.update_attributes!(api: false)
      end
      it 'is not returned' do
        expect { client.send(:channels, @cursor_params).resource }.to raise_error Faraday::ClientError do |e|
          json = JSON.parse(e.response[:body])
          expect(json['error']).to eq 'Not Found'
        end
      end
    end
    context 'with a team api token' do
      before do
        team.update_attributes!(api_token: 'token')
      end
      it 'is not returned without a team api token' do
        expect { client.send(:channels, @cursor_params).resource }.to raise_error Faraday::ClientError do |e|
          json = JSON.parse(e.response[:body])
          expect(json['error']).to eq 'Access Denied'
        end
      end
      it 'is not returned with the wrong team api token' do
        client.headers.update('X-Access-Token' => 'invalid')
        expect { client.send(:channels, @cursor_params).resource }.to raise_error Faraday::ClientError do |e|
          json = JSON.parse(e.response[:body])
          expect(json['error']).to eq 'Access Denied'
        end
      end
      it 'is returned with the correct team api token' do
        client.headers.update('X-Access-Token' => 'token')
        returned_intances = client.send(:channels, @cursor_params)
        expect(returned_intances.count).to eq 2
      end
    end
  end
end
