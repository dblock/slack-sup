shared_examples_for 'a team token api' do |model|
  let(:model_s) { model.name.underscore.to_sym }
  let(:model_ps) { model.name.underscore.pluralize.to_sym }
  context model.name do
    let(:instance) { Fabricate(model_s) }

    context 'with team api off' do
      before do
        instance.team.update_attributes!(api: false)
      end
      it 'is not returned' do
        expect { client.send(model_s, id: instance.id.to_s).resource }.to raise_error Faraday::ClientError do |e|
          json = JSON.parse(e.response[:body])
          expect(json['error']).to eq 'Not Found'
        end
      end
    end
    context 'with a team api token' do
      before do
        instance.team.update_attributes!(api_token: 'token')
      end
      it 'is not returned without a team api token' do
        expect { client.send(model_s, id: instance.id.to_s).resource }.to raise_error Faraday::ClientError do |e|
          json = JSON.parse(e.response[:body])
          expect(json['error']).to eq 'Access Denied'
        end
      end
      it 'is not returned with the wrong team api token' do
        client.headers.update('X-Access-Token' => 'invalid')
        expect { client.send(model_s, id: instance.id.to_s).resource }.to raise_error Faraday::ClientError do |e|
          json = JSON.parse(e.response[:body])
          expect(json['error']).to eq 'Access Denied'
        end
      end
      it 'is returned with the correct team api token' do
        client.headers.update('X-Access-Token' => 'token')
        returned_intance = client.send(model_s, id: instance.id.to_s)
        expect(returned_intance.id).to eq instance.id.to_s
      end
    end
  end
  context model.name.underscore.pluralize do
    let(:cursor_params) { @cursor_params || { team_id: team.id.to_s } }

    before do
      2.times { Fabricate(model_s) }
    end

    context 'with team api off' do
      before do
        team.update_attributes!(api: false)
      end
      it 'is not returned' do
        expect { client.send(model_ps, cursor_params).resource }.to raise_error Faraday::ClientError do |e|
          json = JSON.parse(e.response[:body])
          expect(json['error']).to eq 'Not Found'
        end
      end
    end
    context 'with a team api token' do
      before do
        team.update_attributes!(api_token: 'token')
      end
      it 'is not returned without a team api token' do
        expect { client.send(model_ps, cursor_params).resource }.to raise_error Faraday::ClientError do |e|
          json = JSON.parse(e.response[:body])
          expect(json['error']).to eq 'Access Denied'
        end
      end
      it 'is not returned with the wrong team api token' do
        client.headers.update('X-Access-Token' => 'invalid')
        expect { client.send(model_ps, cursor_params).resource }.to raise_error Faraday::ClientError do |e|
          json = JSON.parse(e.response[:body])
          expect(json['error']).to eq 'Access Denied'
        end
      end
      it 'is returned with the correct team api token' do
        client.headers.update('X-Access-Token' => 'token')
        returned_intances = client.send(model_ps, cursor_params)
        expect(returned_intances.count).to eq 2
      end
    end
  end
end
