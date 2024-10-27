require 'spec_helper'

describe Api::Endpoints::DataEndpoint do
  include Api::Test::EndpointTest

  let!(:team) { Fabricate(:team, api: true) }

  it 'returns team stats' do
    get "/api/data?team_id=#{team.id}&access_token=#{CGI.escape(team.short_lived_token)}"
    expect(last_response.status).to eq 200
    expect(last_response.headers['Content-Type']).to eq 'application/zip'
    expect(last_response.headers['Content-Disposition']).to eq "attachment; filename=#{team.team_id}.zip"
    expect(last_response.body.length).not_to be 0
  end

  it 'does not re-generate data for an hour' do
    expect_any_instance_of(Team).to receive(:export_zip!).once.and_call_original
    2.times { get "/api/data?team_id=#{team.id}&access_token=#{CGI.escape(team.short_lived_token)}" }
    expect(last_response.status).to eq 200
    expect(last_response.headers['Content-Type']).to eq 'application/zip'
    expect(last_response.headers['Content-Disposition']).to eq "attachment; filename=#{team.team_id}.zip"
    expect(last_response.body.length).not_to be 0
  end

  it 're-generates data after an hour' do
    allow(Team).to receive(:find).and_return(team)
    allow(team).to receive(:export_zip!).and_call_original
    get "/api/data?team_id=#{team.id}&access_token=#{CGI.escape(team.short_lived_token)}"
    Timecop.travel(2.hours.from_now) do
      get "/api/data?team_id=#{team.id}&access_token=#{CGI.escape(team.short_lived_token)}"
      expect(last_response.status).to eq 200
      expect(last_response.headers['Content-Type']).to eq 'application/zip'
      expect(last_response.headers['Content-Disposition']).to eq "attachment; filename=#{team.team_id}.zip"
      expect(last_response.body.length).not_to be 0
    end
    expect(team).to have_received(:export_zip!).twice
  end

  it 'does not return team stats with an invalid token' do
    get "/api/data?team_id=#{team.id}&access_token=expired"
    expect(last_response.status).to eq 401
  end
end
