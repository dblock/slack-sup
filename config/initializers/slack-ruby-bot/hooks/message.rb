module SlackRubyBot
  module Hooks
    class Message
      # HACK: order command classes predictably
      def command_classes
        [
          SlackSup::Commands::Help,
          SlackSup::Commands::Subscription,
          SlackSup::Commands::Opt,
          SlackSup::Commands::Set
        ]
      end
    end
  end
end
