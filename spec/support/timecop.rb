require 'timecop'

RSpec.configure do |config|
  config.before do
    Timecop.return
  end
end
