# frozen_string_literal: true

require 'rails_helper'

resource 'v1 Users > Authentication' do
  let!(:user) { create(:user, password: 'correct_password') }

  post '/api/v1/users/sign_in' do
    with_options scope: :user, required: true do
      parameter :email
      parameter :password
    end

    let!(:headers) do
      { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }
    end

    let(:params) do |ex|
      { user: { email: user.email, password: ex.metadata[:password] } }
    end

    context 'when params are correct', password: 'correct_password' do
      it 'POST sign_in [valid]' do
        do_request

        expect(response_status).to eq 200
        expect(response_json.dig('data', 'jwt_token')).to be_present
      end
    end

    context 'when params are incorrect', password: 'incorrect_password' do
      it 'POST sign_in [invalid]' do
        do_request

        expect(response_status).to eq 401
      end
    end

    let(:raw_post) { params.to_json }
  end

  delete '/api/v1/users/sign_out' do
    it 'DELETE sign_out' do
      do_request

      expect(response_status).to eq 204
    end
  end
end
