RSpec.shared_context :event do
  include Rack::Test::Methods

  def app
    SlackRubyBotServer::Api::Middleware.instance
  end

  let!(:team) { Fabricate(:team, bot_user_id: 'bot_user_id') }
  let(:event) { {} }
  let(:event_envelope) do
    {
      token: 'deprecated',
      api_app_id: 'A19GAJ72T',
      event: {
        message_ts: '1547842100.001400'
      }.merge(event),
      type: 'event_callback',
      event_id: 'EvFGTNRKLG',
      event_time: 1_547_842_101,
      authed_users: ['U04KB5WQR']
    }
  end

  before do
    allow_any_instance_of(Slack::Events::Request).to receive(:verify!)
  end
end

RSpec::Matchers.define :respond_with_slack_message do |expected|
  def parse(actual)
    actual = { message: actual } unless actual.is_a?(Hash)
    attachments = actual[:attachments]
    attachments = [attachments] unless attachments.nil? || attachments.is_a?(Array)
    [actual[:channel] || 'channel', actual[:user] || 'user', actual[:message], attachments]
  end

  match do |actual|
    channel, user, message, attachments = parse(actual)

    allow(Team).to receive(:where).with(team_id: team.team_id).and_return([team])

    allow(Team).to receive(:where).with('_id' => team._id).and_return(double.tap do |where_scope|
      allow(where_scope).to receive(:limit).and_return(double.tap do |limit_scope|
        allow(limit_scope).to receive(:first).and_return(team)
      end)
    end)

    allow(team.slack_client).to receive(:chat_postMessage) do |options|
      @messages ||= []
      @messages.push options
    end

    begin
      SlackRubyBotServer::Events.config.run_callbacks(
        :event,
        %w[event_callback app_mention],
        Slack::Messages::Message.new(
          'team_id' => team.team_id,
          'event' => {
            'user' => user || 'user_id',
            'channel' => channel || 'channel_id',
            'text' => message,
            'attachments' => attachments
          }
        )
      )
    rescue Mongoid::Errors::Validations => e
      m = e.document.errors.messages.transform_values(&:uniq).values.join(', ')
      Api::Middleware.logger.warn(m)
      expect(m).to eq(expected)
      return true
    rescue StandardError => e
      Api::Middleware.logger.warn(e.message)
      expect(e.message).to eq(expected)
      return true
    end

    matcher = have_received(:chat_postMessage).once
    matcher = matcher.with(hash_including(channel: channel, text: expected)) if channel && expected

    expect(team.slack_client).to matcher

    true
  end

  failure_message do |_actual|
    message = "expected to receive message with text: #{expected} once,\n received:"
    message += @messages&.any? ? @messages.inspect : 'none'
    message
  end
end
