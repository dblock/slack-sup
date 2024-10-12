require 'spec_helper'

describe 'Homepage', :js, type: :feature do
  before do
    ENV['SLACK_CLIENT_ID'] = 'client_id'
    ENV['SLACK_CLIENT_SECRET'] = 'client_secret'
  end

  after do
    ENV.delete 'SLACK_CLIENT_ID'
    ENV.delete 'SLACK_CLIENT_SECRET'
  end

  context 'v1' do
    before do
      visit '/?version=1'
    end

    it 'displays index.html page' do
      expect(title).to eq("S'Up for Slack Teams - Generate Fresh Triads of Team Members to Meet Every Week")
    end

    it 'includes a link to add to slack with the client id' do
      expect(find("a[href='https://slack.com/oauth/authorize?scope=bot,users.profile:read&client_id=#{ENV.fetch('SLACK_CLIENT_ID', nil)}']"))
    end
  end

  context 'v2' do
    before do
      visit '/'
    end

    it 'redirects' do
      expect(current_url).to eq('https://sup2.playplay.io/')
    end
  end
end
