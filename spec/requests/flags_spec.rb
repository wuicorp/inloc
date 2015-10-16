require 'rails_helper'

describe 'Flags API', type: :request do
  let(:access_token) { create(:access_token) }
  let(:token) { access_token.token }
  let(:auth_headers) { { authorization: "Bearer #{token}" } }

  let(:response_body) { JSON.parse(response.body) }

  describe 'GET /flags' do
    let(:flag1) do
      Flag.create(
        application_id: access_token.application_id,
        longitude: '0.0',
        latitude: '0.0',
        radius: '5'
      )
    end

    let(:flag2) do
      Flag.create(
        application_id: access_token.application_id,
        longitude: '0.000045',
        latitude: '0.0',
        radius: '5'
      )
    end

    let(:flag3) do
      Flag.create(
        application_id: access_token.application_id,
        longitude: '0.001',
        latitude: '0.0',
        radius: '5'
      )
    end

    before do
      flag1
      flag2
      flag3
      get('/api/v1/flags', params, auth_headers)
    end

    context 'with valid parameters' do
      let(:params) { { longitude: '0.0', latitude: '0.0' } }

      it 'responds with 200' do
        expect(response.status).to be 200
      end

      it 'responds with the right flags' do
        expect(response_body)
          .to eq('data' => [
                   { 'id' => flag1.id.to_s,
                     'type' => 'flags',
                     'attributes' => {
                       'longitude' => flag1.longitude.to_s,
                       'latitude' => flag1.latitude.to_s,
                       'radius' => flag1.radius
                     }
                   },
                   { 'id' => flag2.id.to_s,
                     'type' => 'flags',
                     'attributes' => {
                       'longitude' => flag2.longitude.to_s,
                       'latitude' => flag2.latitude.to_s,
                       'radius' => flag2.radius
                     }
                   }
                 ])
      end
    end

    context 'with missing parameter' do
      let(:params) { { latitude: '0.0' } }

      it 'responds with 422' do
        expect(response.status).to eq 422
      end
    end
  end

  describe 'POST /flags' do
    let(:longitude) { '0.0' }
    let(:latitude) { '0.0' }
    let(:radius) { 10 }

    let(:params) do
      { longitude: longitude,
        latitude: latitude,
        radius: radius }
    end

    subject { post '/api/v1/flags', params, auth_headers }

    context 'with valid attributes' do
      before { subject }

      it 'responds with 201' do
        expect(response.status).to eq 201
      end

      it 'responds with flag attributes' do
        expect(response_body['data']['attributes']).to eq params.stringify_keys
      end

      it 'adds the flag' do
        expect(Flag.count).to eq 1
      end
    end

    context 'with invalid attributes' do
      let(:longitude) { 'aaa' }

      before { subject }

      it 'respond with 422' do
        expect(response.status).to eq 422
      end

      it 'responds with errored fields' do
        expect(response_body['errors'])
          .to eq([{ 'id' => 'longitude',
                    'title' => 'Longitude is not a number' }])
      end
    end
  end

  describe 'PUT /flags/:id' do
    let(:longitude) { '0.0' }
    let(:latitude) { '0.0' }
    let(:radius) { 10 }

    let(:params) do
      { longitude: longitude,
        latitude: latitude,
        radius: radius }
    end

    subject { put "/api/v1/flags/#{id}", params, auth_headers }

    context 'without existing flag' do
      let(:id) { 'some-unexisting' }

      before { subject }

      it 'is expected to respond with 404' do
        expect(response.status).to eq 404
      end
    end

    context 'with existing flag' do
      let(:old_latitude) { '0.2' }

      let(:flag) do
        Flag.create(
          params.merge(application_id: access_token.application_id,
                       latitude: old_latitude)
        )
      end

      let(:id) { flag.id }

      before { subject }

      context 'with valid attributes' do
        it 'responds with 200' do
          expect(response.status).to eq 200
        end

        it 'responds with flag attributes' do
          expect(response_body['data']['attributes']).to eq params.stringify_keys
        end

        it 'updates the flag' do
          expect(Flag.last.latitude).to eq latitude.to_f
        end
      end

      context 'with invalid attributes' do
        let(:latitude) { 'xxx' }

        it 'respond with 422' do
          expect(response.status).to eq 422
        end

        it 'responds with errored fields' do
          expect(response_body['errors'])
            .to eq([{ 'id' => 'latitude',
                      'title' => 'Latitude is not a number' }])
        end
      end
    end
  end

  describe 'DELETE /flags/:id' do
    subject { delete "/api/v1/flags/#{id}", {}, auth_headers }

    context 'with existing flag' do
      context 'with existing flag' do
        let(:flag) do
          Flag.create(application_id: access_token.application_id,
                      longitude: '0.0',
                      latitude: '0.0',
                      radius: '5')
        end

        let(:id) { flag.id }

        it 'respond with 200' do
          subject
          expect(response.status).to be 200
        end
      end

      context 'with unexisting flag' do
        let(:id) { 'whatever' }

        it 'responds with 404' do
          subject
          expect(response.status).to be 404
        end

        it 'responds with not found error' do
          subject
          expect(response_body['errors']).to eq([{ 'id' => id,
                                                   'title' => 'not found' }])
        end
      end
    end
  end
end
