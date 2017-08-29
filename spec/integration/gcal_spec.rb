require 'spec_helper'

describe 'GCal', js: true, type: :feature do
  it 'errors without GOOGLE_API_CLIENT_ID' do
    visit '/gcal?1'
    expect(find('#messages')).to have_text('Missing GOOGLE_API_CLIENT_ID.')
  end
  context 'with GOOGLE_API_CLIENT_ID' do
    before do
      ENV['GOOGLE_API_CLIENT_ID'] = 'client-id'
    end
    after do
      ENV.delete('GOOGLE_API_CLIENT_ID')
    end
    it 'errors without any parameters' do
      visit '/gcal?2'
      expect(find('#messages', visible: true)).to have_text("Missing or invalid S'Up ID.")
    end
    it 'errors without a sup ID' do
      visit '/gcal?dt=1483394400'
      expect(find('#messages', visible: true)).to have_text("Missing or invalid S'Up ID.")
    end
    context 'with a team' do
      let(:team) { Fabricate(:team) }
      let!(:sup) { Fabricate(:sup, team: team, channel_id: 'sup-channel-id') }
      let(:monday) { DateTime.parse('2017/1/2 8:00 AM EST').utc }
      it 'errors without a sup time' do
        visit "/gcal?sup_id=#{sup.id}"
        expect(find('#messages', visible: true)).to have_text("Missing or invalid S'Up time.")
      end
      it 'creates a calendar event' do
        # Firefox may fail locally with idpiframe_initialization_failed
        visit "/gcal?sup_id=#{sup.id}&dt=1483394400"
        expect(find('#messages', visible: true)).to have_text("Adding S'Up calendar for on Monday, January 02, 2017 at 5:00 pm ...")
      end
    end
  end
end
