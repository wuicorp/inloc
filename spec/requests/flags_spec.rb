require 'rails_helper'

describe 'Flags API', type: :request do
  let(:access_token) { create(:access_token) }
  let(:token) { access_token.token }
  let(:auth_headers) { { authorization: "Bearer #{token}" } }

  let(:response_body) { JSON.parse(response.body) }

  describe 'GET /flags' do
    let(:flag1) do
      { id: '1',
        longitude: '0.0',
        latitude: '0.0',
        radius: '5' }
    end

    let(:flag2) do
      { id: '2',
        longitude: '0.000045',
        latitude: '0.0',
        radius: '5' }
    end

    let(:flag3) do
      { id: '3',
        longitude: '0.001',
        latitude: '0.0',
        radius: '5' }
    end

    let(:flags_map) do
      FlagsMap.find_or_create_by(application_id: access_token.application_id)
    end

    before do
      flags_map.tap do |m|
        m.add_flag(flag1)
        m.add_flag(flag2)
        m.add_flag(flag3)
      end.save!

      get('/api/v1/flags', params, auth_headers)
    end

    context 'with valid parameters' do
      let(:params) { { longitude: '0.0', latitude: '0.0' } }

      it 'responds with 200' do
        expect(response.status).to be 200
      end

      it 'responds with the right flags' do
        expect(response_body['data'])
          .to eq [{ 'type' => 'flags', 'id' => flag1[:id] },
                  { 'type' => 'flags', 'id' => flag2[:id] }]
      end
    end

    context 'with missing parameter' do
      let(:params) { { latitude: '0.0' } }

      it 'responds with 422' do
        expect(response.status).to be 422
      end
    end
  end

  describe 'POST /flags' do
    let(:flag_id) { 'flag-id' }
    let(:longitude) { '0.0' }
    let(:latitude) { '0.0' }
    let(:radius) { '10' }

    let(:params) do
      { id: flag_id,
        longitude: longitude,
        latitude: latitude,
        radius: radius }
    end

    let(:flags_map) do
      FlagsMap.find_by(application_id: access_token.application_id).tap do |m|
        m.add_flag(params.merge(id: 'whatever'))
        m.save
      end
    end

    before { post '/api/v1/flags', params, auth_headers }

    shared_examples 'adds the flag' do
      it 'responds with 201' do
        expect(response).to be_success
      end

      it 'responds with flag attributes' do
        expect(response_body).to eq params.stringify_keys
      end

      it 'adds the flag' do
        expect(flags_map.reload.flags.pluck(:id)).to include flag_id
      end
    end

    context 'with unexisting flag' do
      it_behaves_like 'adds the flag'
    end

    context 'with existing flag' do
      before { flags_map.add_flag(params) }

      it_behaves_like 'adds the flag'
    end

    context 'with invalid attributes' do
      let(:longitude) { 'aaa' }

      it 'respond with 422' do
        expect(response).to be_unprocessable
      end

      it 'responds with errored fields' do
        expect(response_body['errors']).to include 'longitude'
      end
    end
  end

  describe 'DELETE /flags/:id' do
    let(:flag_id) { 'flag_id' }

    subject { delete "/api/v1/flags/#{flag_id}", {}, auth_headers }

    context 'with existing flag' do
      let(:flags_map) do
        FlagsMap.find_or_create_by(application_id: access_token.application_id)
      end

      context 'with existing flag' do
        before do
          flags_map.add_flag(id: flag_id,
                             longitude: '0.0',
                             latitude: '0.0',
                             radius: '5')
          flags_map.save
        end

        it 'respond with 200' do
          subject
          expect(response.status).to be 200
        end
      end

      context 'with unexisting flag' do
        it 'responds with 404' do
          subject
          expect(response.status).to be 404
        end
      end
    end
  end
end
