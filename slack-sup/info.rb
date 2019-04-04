module SlackSup
  INFO = <<~EOS.freeze
    Slack Sup' #{SlackSup::VERSION}

    © 2017 Daniel Doubrovkine & Contributors, MIT License
    https://twitter.com/dblockdotorg

    Service at #{SlackRubyBotServer::Service.url}
    Open-Source at https://github.com/dblock/slack-sup
  EOS
end
