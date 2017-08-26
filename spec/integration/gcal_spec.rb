require 'spec_helper'

describe 'GCal', js: true, type: :feature do
  let(:team) { Fabricate(:team) }
  let!(:sup) { Fabricate(:sup, team: team, channel_id: 'sup-channel-id') }
  let(:monday) { DateTime.parse('2017/1/2 8:00 AM EST').utc }
  it 'creates a calendar event' do
    visit "/gcal?sup_id=#{sup.id}&dt=1483394400"
    expect(find('#messages')).to have_text("Adding S'Up calendar for on Monday, January 02, 2017 at 5:01 pm ...")
  end
end
