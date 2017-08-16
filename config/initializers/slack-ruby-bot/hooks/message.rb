module SlackRubyBot
  module Hooks
    class Message
      # HACK: order command classes predictably
      def command_classes
        [
          SlackSup::Commands::Help,
          SlackSup::Commands::Subscription
        ]
      end
    end
  end
end
