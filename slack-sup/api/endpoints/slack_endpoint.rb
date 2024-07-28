module Api
  module Endpoints
    class SlackEndpoint < Grape::API
      format :json

      namespace :slack do
        desc 'Respond to interactive slack buttons and actions.'

        params do
          requires :payload, type: String
        end

        post '/action' do
          payload = Hashie::Mash.new(JSON.parse(params[:payload]))
          error! 'Message token is not coming from Slack.', 401 if ENV.key?('SLACK_VERIFICATION_TOKEN') && payload.token != ENV['SLACK_VERIFICATION_TOKEN']
          error! 'Missing actions.', 400 unless payload.actions
          error! 'Missing action.', 400 unless payload.actions.first

          case payload.actions.first.name
          when 'outcome' then

            sup = Sup.find(payload.callback_id) || error!('Sup Not Found', 404)
            sup.update_attributes!(outcome: payload.actions.first.value)

            Api::Middleware.logger.info "Updated team #{sup.round.team}, sup #{sup} outcome to '#{sup.outcome}'."

            message = Sup::ASK_WHO_SUP_MESSAGE.dup

            message[:attachments].first[:callback_id] = sup.id.to_s
            message[:attachments].first[:actions].each do |action|
              action[:style] = action[:value] == sup.outcome ? 'primary' : 'default'
            end

            message[:text] = Sup::RESPOND_TO_ASK_MESSAGES[sup.outcome]

            {
              as_user: true,
              channel: payload.channel.id,
              ts: payload.original_message.ts,
              token: payload.token
            }.merge(message)

          else
            error!("Unknown Action #{actions.first.name}", 400)
          end
        end
      end
    end
  end
end
