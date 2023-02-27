module SlackSup
  module Commands
    module Mixins
      module Subscribe
        extend ActiveSupport::Concern

        module ClassMethods
          def subscribe_command(*values, &_block)
            mention(*values) do |data|
              return if data.user == data.team.bot_user_id

              if Stripe.api_key && data.team.reload.subscription_expired?
                data.team.slack_client.chat_postMessage channel: data.channel, text: data.team.subscribe_text
                logger.info "#{data.team}, user=#{data.user}, text=#{data.text}, subscription expired"
              else
                yield data
              end
            end
          end
        end
      end
    end
  end
end
