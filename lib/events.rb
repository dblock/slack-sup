SlackRubyBotServer::Events.configure do |config|
  def parse(event)
    team = Team.where(team_id: event[:event][:team]).first || raise("Cannot find team with ID #{event[:event][:team]}.")
    data = Slack::Messages::Message.new(event[:event]).merge(team: team)
    return nil unless data.user == data.team.bot_user_id

    data
  end

  config.on :event, 'event_callback', 'member_joined_channel' do |event|
    data = parse(event)
    next unless data

    Api::Middleware.logger.info "#{data.team.name}: bot joined ##{data.channel}."
    data.team.join_channel!(data.channel, data.inviter)

    text =
      "Hi there! I'm your team's S'Up bot. " \
      "Thanks for trying me out. Type `#{data.team.bot_name} help` for instructions. " \
      "I plan to setup some S'Ups via Slack DM for all users in this channel next Monday. " \
      'You may want to `set size`, `set day`, `set timezone`, or `set sync now` users before then.'.freeze

    data.team.slack_client.chat_postMessage(channel: data.channel, text: text)

    { ok: true }
  end

  config.on :event, 'event_callback', 'member_left_channel' do |event|
    data = parse(event)
    next unless data

    Api::Middleware.logger.info "#{data.team.name}: bot left ##{data.channel}."
    data.team.leave_channel!(data.channel)

    { ok: true }
  end
end
