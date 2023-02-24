module SlackSup
  class Server < SlackRubyBotServer::RealTime::Server
    on :member_joined_channel do |client, data|
      next unless data.user == client.owner.bot_user_id

      logger.info "#{client.owner.name}: bot joined ##{data.channel}."
      client.owner.join_channel!(data.channel, data.inviter)

      text =
        "Hi there! I'm your team's S'Up bot. " \
        "Thanks for trying me out. Type `#{client.owner.bot_name} help` for instructions. " \
        "I plan to setup some S'Ups via Slack DM for all users in this channel next Monday. " \
        'You may want to `set size`, `set day`, `set timezone`, or `set sync now` users before then.'.freeze

      client.say(channel: data.channel, text: text)
    end

    on :member_left_channel do |client, data|
      next unless data.user == client.owner.bot_user_id

      logger.info "#{client.owner.name}: bot left ##{data.channel}."
      client.owner.leave_channel!(data.channel)
    end
  end
end
