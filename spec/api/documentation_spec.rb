require 'spec_helper'

describe Api do
  include Api::Test::EndpointTest

  context 'swagger root' do
    subject do
      get '/api/swagger_doc'
      JSON.parse(last_response.body)
    end
    it 'documents root level apis' do
      expect(subject['paths'].keys.sort).to eq [
        '/api/channels',
        '/api/channels/{id}',
        '/api/credit_cards',
        '/api/rounds',
        '/api/rounds/{id}',
        '/api/slack/action',
        '/api/slack/command',
        '/api/slack/event',
        '/api/stats',
        '/api/status',
        '/api/subscriptions',
        '/api/sups',
        '/api/sups/{id}',
        '/api/teams',
        '/api/teams/{id}',
        '/api/users',
        '/api/users/{id}'
      ]
    end
  end

  context 'teams' do
    subject do
      get '/api/swagger_doc/teams'
      JSON.parse(last_response.body)
    end
    it 'documents teams apis' do
      expect(subject['paths'].keys.sort).to eq [
        '/api/teams/{id}',
        '/api/teams'
      ].sort
    end
  end
end
