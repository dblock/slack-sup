module SlackRubyBot
  module Hooks
    class Message
      # HACK: order command classes predictably
      def command_classes
        [
          SlackSup::Commands::Help,
          SlackSup::Commands::Subscription,
          SlackSup::Commands::Opt
        ]
      end
    end
  end
end
