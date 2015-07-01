require 'rails_helper'

describe 'Flags API', type: :request do
  let(:access_token) { create(:access_token) }
  let(:token) { access_token.token }
  let(:auth_headers) { { authorization: "Bearer #{token}" } }

  let(:response_body) { JSON.parse(response.body).symbolize_keys }

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
      FlagsMap.find_by(application_id: access_token.application_id)
    end

    before { post '/api/v1/flags', params, auth_headers }

    shared_examples 'adds the flag' do
      it 'responds with 201' do
        expect(response).to be_success
      end

      it 'responds with flag attributes' do
        expect(response_body).to eq params
      end

      it 'adds the flag' do
        expect(flags_map.reload.flags).to include flag_id
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
        expect(response_body[:errors]).to include 'longitude'
      end
    end
  end
end
