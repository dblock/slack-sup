SlackRubyBotServer::Events.configure do |config|
  config.on :action, 'interactive_message' do |action|
    payload = action[:payload]
    error! 'Missing actions.', 400 unless payload[:actions]
    error! 'Missing action.', 400 unless payload[:actions].first

    case payload[:actions].first[:name]
    when 'outcome' then
      sup = Sup.find(payload[:callback_id]) || error!('Sup Not Found', 404)
      sup.update_attributes!(outcome: payload[:actions].first[:value])

      Api::Middleware.logger.info "Updated channel #{sup.round.channel}, sup #{sup} outcome to '#{sup.outcome}'."

      message = Sup::ASK_WHO_SUP_MESSAGE.dup

      message[:attachments].first[:callback_id] = sup.id.to_s
      message[:attachments].first[:actions].each do |a|
        a[:style] = a[:value] == sup.outcome ? 'primary' : 'default'
      end

      message[:text] = case sup.outcome
                       when 'later'
                         "Thanks, I'll ask again in a couple of days."
                       else
                         'Thanks for letting me know.'
                      end

      Faraday.post(payload[:response_url], {
        response_type: 'in_channel',
        thread_ts: payload[:original_message][:ts]
      }.merge(message).to_json, 'Content-Type' => 'application/json')
    end

    false
  end
end
