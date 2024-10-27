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
          SlackSup::Commands::Stats,
          SlackSup::Commands::Rounds,
          SlackSup::Commands::Next,
          SlackSup::Commands::GCal,
          SlackSup::Commands::Promote,
          SlackSup::Commands::Demote,
          SlackSup::Commands::Data
        ]
      end
    end
  end
end
