module SlackSup
  class Server < SlackRubyBotServer::RealTime::Server
    on :channel_joined do |client, data|
      logger.info "#{client.owner.name}: joined ##{data.channel['name']}."
      client.say(channel: data.channel['id'], text: "Hi there! I'm your team's S'Up bot. Type `#{client.owner.bot_name} help` for instructions.")
    end
  end
end
