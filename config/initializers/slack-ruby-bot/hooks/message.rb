module SlackRubyBot
  module Hooks
    class Message
      # HACK: order command classes predictably
      def command_classes
        [
          SlackSup::Commands::Help,
          SlackSup::Commands::About,
          SlackSup::Commands::Subscription,
          SlackSup::Commands::Opt,
          SlackSup::Commands::Set,
          SlackSup::Commands::Stats
        ]
      end
    end
  end
end
