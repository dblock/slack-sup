shared_examples_for 'a channel token api' do |model|
  let(:model_s) { model.name.underscore.to_sym }
  let(:model_ps) { model.name.underscore.pluralize.to_sym }
  context model.name do
    let(:instance) { Fabricate(model_s) }

    context 'with channel api off' do
      before do
        instance.channel.update_attributes!(api: false)
      end
      it 'is not returned' do
        expect { client.send(model_s, id: instance.id.to_s).resource }.to raise_error Faraday::ClientError do |e|
          json = JSON.parse(e.response[:body])
          expect(json['error']).to eq 'Access Denied'
        end
      end
    end
    context 'with a channel api token' do
      before do
        instance.channel.update_attributes!(api_token: 'token')
      end
      it 'is not returned without a channel api token' do
        expect { client.send(model_s, id: instance.id.to_s).resource }.to raise_error Faraday::ClientError do |e|
          json = JSON.parse(e.response[:body])
          expect(json['error']).to eq 'Access Denied'
        end
      end
      it 'is not returned with the wrong channel api token' do
        client.headers.update('X-Access-Token' => 'invalid')
        expect { client.send(model_s, id: instance.id.to_s).resource }.to raise_error Faraday::ClientError do |e|
          json = JSON.parse(e.response[:body])
          expect(json['error']).to eq 'Access Denied'
        end
      end
      it 'is returned with the correct channel api token' do
        client.headers.update('X-Access-Token' => 'token')
        returned_intance = client.send(model_s, id: instance.id.to_s)
        expect(returned_intance.id).to eq instance.id.to_s
      end
    end
  end
  context model.name.underscore.pluralize do
    let(:cursor_params) { @cursor_params || { channel_id: channel.id.to_s } }

    before do
      2.times { Fabricate(model_s) }
    end

    context 'with channel api off' do
      before do
        channel.update_attributes!(api: false)
      end
      it 'is not returned' do
        expect { client.send(model_ps, cursor_params).resource }.to raise_error Faraday::ClientError do |e|
          json = JSON.parse(e.response[:body])
          expect(json['error']).to eq 'Access Denied'
        end
      end
    end
    context 'with a channel api token' do
      before do
        channel.update_attributes!(api_token: 'token')
      end
      it 'is not returned without a channel api token' do
        expect { client.send(model_ps, cursor_params).resource }.to raise_error Faraday::ClientError do |e|
          json = JSON.parse(e.response[:body])
          expect(json['error']).to eq 'Access Denied'
        end
      end
      it 'is not returned with the wrong channel api token' do
        client.headers.update('X-Access-Token' => 'invalid')
        expect { client.send(model_ps, cursor_params).resource }.to raise_error Faraday::ClientError do |e|
          json = JSON.parse(e.response[:body])
          expect(json['error']).to eq 'Access Denied'
        end
      end
      it 'is returned with the correct channel api token' do
        client.headers.update('X-Access-Token' => 'token')
        returned_intances = client.send(model_ps, cursor_params)
        expect(returned_intances.count).to eq 2
      end
    end
  end
end
