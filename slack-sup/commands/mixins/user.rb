module SlackSup
  module Commands
    module Mixins
      module User
        extend ActiveSupport::Concern
        include SlackSup::Commands::Mixins::Channel

        module ClassMethods
          def user_command(*values, &_block)
            subscribe_command(*values) do |client, data, match|
              user = client.owner.find_create_or_update_user_in_channel_by_slack_id!(data.channel, data.user)
              yield client, user.is_a?(::User) ? user.channel : nil, user, data, match
            end
          end
        end
      end
    end
  end
end
