require 'spec_helper'

unless ENV['CI']
  describe 'GCal', :js, type: :feature do
    it 'errors without GOOGLE_API_CLIENT_ID' do
      visit '/gcal?1'
      expect(find_by_id('messages')).to have_text('Missing GOOGLE_API_CLIENT_ID.')
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
        expect(find_by_id('messages', visible: true)).to have_text("Missing or invalid S'Up ID.")
      end

      it 'errors without a sup ID' do
        visit '/gcal?dt=1483394400'
        expect(find_by_id('messages', visible: true)).to have_text("Missing or invalid S'Up ID.")
      end

      context 'with a team' do
        let(:team) { Fabricate(:team) }
        let!(:sup) { Fabricate(:sup, team:, channel_id: 'sup-channel-id') }
        let(:monday) { DateTime.parse('2017/1/2 8:00 AM EST').utc }

        it 'errors without a sup time' do
          visit "/gcal?sup_id=#{sup.id}"
          expect(find_by_id('messages', visible: true)).to have_text("Missing or invalid S'Up time.")
        end

        it 'errors without an access token' do
          visit "/gcal?sup_id=#{sup.id}&dt=1483394400"
          expect(find_by_id('messages', visible: true)).to have_text("This link has expired, ask for a new one on your S'Up channel.")
        end

        it 'errors with an expired access token' do
          access_token = team.short_lived_token
          Timecop.travel(30.minutes.from_now)
          visit "/gcal?sup_id=#{sup.id}&dt=1483394400&access_token=#{access_token}"
          expect(find_by_id('messages', visible: true)).to have_text("This link has expired, ask for a new one on your S'Up channel.")
        end

        unless ENV['CI']
          it 'creates a calendar event' do
            # Firefox will fail locally with idpiframe_initialization_failed
            visit "/gcal?sup_id=#{sup.id}&dt=1483394400&access_token=#{sup.team.short_lived_token}"
            expect(find_by_id('messages', visible: true)).to have_text("Adding S'Up calendar for on Monday, January 02, 2017 at 5:00 pm ...")
          end
        end
      end
    end
  end
end
