# frozen_string_literal: true

require 'rails_helper'

resource 'v1 Users > Registration' do
  header 'Content-Type', 'application/json'

  post '/api/v1/users' do
    with_options scope: :user do
      parameter :email, required: true
      parameter :password, required: true
      parameter :password_confirmation, required: true
    end

    context 'when params are correct' do
      let(:email) { 'new_user@example.com' }
      let(:password) { Faker::Internet.password }
      let(:params) do
        {
          user: {
            email: email,
            password: password,
            password_confirmation: password
          }
        }
      end

      it 'PSOT users' do
        do_request
        expect(response_status).to eq 200

        # Access the created user through response (might differ based on your setup)
        expect(User.find(response_json['user']['id']).email).to eq(email)
      end
    end

    context 'when params are invalid' do
      let(:email) { 'invalid_email' }  # Missing domain
      let(:password) { 'short' }  # Too short password

      it 'POST users[error]', document: false do
        do_request

        expect(response_status).to eq 400
        expect(response_json['errors']).to be_present
      end
    end

  end

  let(:raw_post) { params.to_json }
end
