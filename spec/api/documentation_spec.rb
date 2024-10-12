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
        '/api/status',
        '/api/teams/{id}',
        '/api/teams',
        '/api/users/{id}',
        '/api/users',
        '/api/rounds/{id}',
        '/api/rounds',
        '/api/stats',
        '/api/sups/{id}',
        '/api/sups',
        '/api/subscriptions',
        '/api/credit_cards',
        '/api/slack/action'
      ].sort
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
