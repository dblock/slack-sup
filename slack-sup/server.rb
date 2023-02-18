module SlackSup
  class Server < SlackRubyBotServer::RealTime::Server
    on :member_joined_channel do |client, data|
      next unless data.user == client.owner.bot_user_id

      logger.info "#{client.owner.name}: bot joined ##{data.channel}."
      client.owner.join_channel!(data.channel, data.inviter)
      client.say(channel: data.channel, text: "Hi there! I'm your team's S'Up bot. Type `#{client.owner.bot_name} help` for instructions on setting up S'Up in this channel.")
    end

    on :member_left_channel do |client, data|
      next unless data.user == client.owner.bot_user_id

      logger.info "#{client.owner.name}: bot left ##{data.channel}."
      client.owner.leave_channel!(data.channel)
    end
  end
end
