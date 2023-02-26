module SlackRubyBot
  module Hooks
    class Message
      # HACK: order command classes predictably
      def command_classes
        [
          SlackSup::Commands::Help,
          SlackSup::Commands::About,
          SlackSup::Commands::Subscription,
          SlackSup::Commands::Unsubscribe,
          SlackSup::Commands::Opt,
          SlackSup::Commands::Set,
          SlackSup::Commands::Sync,
          SlackSup::Commands::Stats,
          SlackSup::Commands::Rounds,
          SlackSup::Commands::Next,
          SlackSup::Commands::GCal
        ]
      end
    end
  end
end
