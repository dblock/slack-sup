require 'spec_helper'

describe Api::Middleware do
  include Rack::Test::Methods

  let(:app) { described_class.instance }

  %w[/ /privacy.html /subscribe.html /update_cc.html /gcal.html].each do |path|
    it "versions local assets and revalidates #{path}" do
      get path

      expect(last_response.status).to eq 200
      expect(last_response.headers['Cache-Control']).to eq 'private, no-cache'
      document = Capybara.string(last_response.body)
      assets = document.all('script[src^="/"], link[href^="/"], img[src^="/"], meta[name="msapplication-TileImage"]', visible: :all)
      expect(assets).not_to be_empty
      expect(assets.map { |asset| asset[:src] || asset[:href] || asset[:content] }).to all(match(/\?v=[a-f0-9]{64}\z/))
    end
  end

  it 'versions checkout images in JavaScript and data attributes' do
    image = "/img/icon.png?v=#{Digest::SHA256.file('public/img/icon.png').hexdigest}"
    get '/subscribe.html'
    expect(last_response.body).to include("image: #{image.to_json}")

    get '/update_cc.html'
    expect(Capybara.string(last_response.body).find('script[data-image]', visible: :all)['data-image']).to eq image
  end

  it 'returns a content ETag and a bodyless 304 for matching static content' do
    get '/js/sup.js'
    etag = last_response.headers['ETag']
    expect(etag).to eq %("#{Digest::SHA256.file('public/js/sup.js').hexdigest}")
    expect(last_response.headers['Last-Modified']).to eq File.mtime('public/js/sup.js').httpdate
    expect(last_response.headers['Cache-Control'].to_s).not_to match(/immutable|max-age/)

    get '/js/sup.js', {}, 'HTTP_IF_NONE_MATCH' => etag
    expect(last_response.status).to eq 304
    expect(last_response.body).to be_empty
  end

  it 'ignores a matching timestamp when the content ETag does not match' do
    get '/js/sup.js', {}, 'HTTP_IF_NONE_MATCH' => '"old-content"',
                          'HTTP_IF_MODIFIED_SINCE' => File.mtime('public/js/sup.js').httpdate

    expect(last_response.status).to eq 200
    expect(last_response.body).to eq File.read('public/js/sup.js')
  end

  it 're-renders nested artwork versions even when the stylesheet source is unchanged' do
    get '/css/agency.css'
    expect(last_response.content_type).to eq 'text/css; charset=utf-8'
    expect(last_response.headers['Cache-Control']).to eq 'private, no-cache'
    image = 'public/img/header-bg.jpg'
    expect(last_response.body).to include("/img/header-bg.jpg?v=#{Digest::SHA256.file(image).hexdigest}")
    previous_body = last_response.body
    previous_mtime = File.mtime('public/css/agency.css.erb')
    allow(Digest::SHA256).to receive(:file).and_call_original
    allow(Digest::SHA256).to receive(:file).with(File.expand_path(image)).and_return(double(hexdigest: 'a' * 64))
    allow(Digest::SHA256).to receive(:file).with(image).and_return(double(hexdigest: 'a' * 64))

    get '/css/agency.css', {}, 'HTTP_IF_MODIFIED_SINCE' => previous_mtime.httpdate

    expect(last_response.status).to eq 200
    expect(last_response.body).not_to eq previous_body
    expect(last_response.body).to include("/img/header-bg.jpg?v=#{'a' * 64}")
    expect(File.mtime('public/css/agency.css.erb')).to eq previous_mtime
  end
end
