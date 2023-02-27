SlackRubyBotServer.configure do |config|
  config.oauth_version = :v2
  config.oauth_scope = [
    'app_mentions:read',
    'channels:history',
    'channels:read',
    'chat:write',
    'groups:history',
    'groups:read',
    'im:history',
    'im:read',
    'im:write',
    'mpim:history',
    'mpim:read',
    'mpim:write',
    'users:read',
    'users.profile:read'
  ]
end
