require 'spec_helper'

describe 'Teams', js: true, type: :feature do
  before do
    ENV['SLACK_CLIENT_ID'] = 'client_id'
    ENV['SLACK_CLIENT_SECRET'] = 'client_secret'
  end
  after do
    ENV.delete 'SLACK_CLIENT_ID'
    ENV.delete 'SLACK_CLIENT_SECRET'
  end
  context 'oauth', vcr: { cassette_name: 'auth_test' } do
    it 'registers a team' do
      allow_any_instance_of(Team).to receive(:inform!).with(Team::INSTALLED_TEXT)
      allow_any_instance_of(Team).to receive(:ping!).and_return(ok: true)
      expect(SlackRubyBotServer::Service.instance).to receive(:start!)
      oauth_access = {
        'access_token' => 'token',
        'token_type' => 'bot',
        'bot_user_id' => 'bot_user_id',
        'team' => {
          'id' => 'team_id',
          'name' => 'team_name'
        },
        'authed_user' => {
          'id' => 'activated_user_id',
          'access_token' => 'user_token',
          'token_type' => 'user'
        }
      }
      allow_any_instance_of(Slack::Web::Client).to receive(:oauth_v2_access).with(hash_including(code: 'code')).and_return(oauth_access)
      expect do
        visit '/?code=code'
        expect(page.find('#messages')).to have_content 'Team successfully registered! Check your DMs.'
      end.to change(Team, :count).by(1)
    end
  end
  context 'homepage' do
    before do
      visit '/'
    end
    it 'displays index.html page' do
      expect(title).to eq("S'Up for Slack Teams - Generate Fresh Triads of Team Members to Meet Every Week")
    end
    it 'includes a link to add to slack with the client id' do
      url = "#{SlackRubyBotServer::Config.oauth_authorize_url}?scope=#{SlackRubyBotServer::Config.oauth_scope_s.gsub('+', ',')}&client_id=#{ENV['SLACK_CLIENT_ID']}"
      expect(find("a[href='#{url}']"))
    end
  end
end
