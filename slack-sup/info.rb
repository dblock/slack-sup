module SlackSup
  INFO = <<~EOS.freeze
    Slack Sup' #{SlackSup::VERSION}

    © 2017-2019 Daniel Doubrovkine, Vestris LLC & Contributors, MIT License
    https://www.vestris.com

    Service at #{SlackRubyBotServer::Service.url}
    Open-Source at https://github.com/dblock/slack-sup
  EOS
end
