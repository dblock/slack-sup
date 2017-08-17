module SlackSup
  class Server < SlackRubyBotServer::Server
    CHANNEL_JOINED_MESSAGE = "Hi there! I'm your team's S'Up bot. Type `@sup help` for instructions.".freeze

    on :channel_joined do |client, data|
      logger.info "#{client.owner.name}: joined ##{data.channel['name']}."
      client.say(channel: data.channel['id'], text: CHANNEL_JOINED_MESSAGE)
    end
  end
end
