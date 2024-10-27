RSpec.shared_context 'uses temp dir' do
  around do |example|
    Dir.mktmpdir('rspec-') do |dir|
      @tmp = dir
      example.run
    end
  end

  attr_reader :tmp
end
