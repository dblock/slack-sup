require 'spec_helper'

describe Export do
  include_context 'uses temp dir'

  let(:team) { Fabricate(:team) }
  let(:export) { Fabricate(:export, team:) }

  before do
    allow(team.slack_client).to receive(:conversations_open).and_return(Hashie::Mash.new('channel' => { 'id' => 'dm' }))
  end

  it 'export!' do
    expect(export).to receive(:notify!)
    filename = export.export!
    expect(File.exist?(filename)).to be true
  end

  it 'notify!' do
    allow(team).to receive(:short_lived_token).and_return('token')
    expect(export.team.slack_client).to receive(:chat_postMessage).with(
      hash_including(
        attachments: [
          actions: [
            text: 'Download',
            type: 'button',
            url: "#{SlackRubyBotServer::Service.url}/api/data/#{export.id}?access_token=token"
          ],
          attachment_type: 'default',
          text: ''
        ],
        channel: 'dm',
        text: 'Click here to download your team data.'
      )
    )
    export.notify!
  end
end
