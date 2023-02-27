module SlackSup
  module Commands
    module Mixins
      module Channel
        extend ActiveSupport::Concern
        include SlackSup::Commands::Mixins::Subscribe

        module ClassMethods
          def channel_command(*values, &_block)
            subscribe_command(*values) do |data|
              channel = data.team.find_create_or_update_channel_by_channel_id!(data.channel, data.user)
              yield channel, data
            end
          end
        end
      end
    end
  end
end
