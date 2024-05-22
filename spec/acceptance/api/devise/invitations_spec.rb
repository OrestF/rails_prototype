# frozen_string_literal: true

require 'rails_helper'

resource 'v1 Users > Authentication' do
  header 'Content-Type', 'application/json'

  let(:user) { create(:user) }

  put '/api/v1/users/invitation' do
    with_options scope: :user do
      parameter :invitation_token, required: true
      parameter :password, required: true
      parameter :password_confirmation, required: true
    end

    context 'when params are correct' do
      before { user.invite! }

      let(:password) { Faker::Internet.password }
      let!(:user) { create(:user, :locked) }
      let(:params) do
        {
          user:
            {
              invitation_token: user.raw_invitation_token,
              password: password,
              password_confirmation: password
            }
        }
      end

      it 'PUT invitation' do
        do_request
        expect(response_status).to eq 200
        expect(response_json['user']['email']).to eq user.email
        expect(user.reload.invitation_accepted_at).to be_present
      end
    end
  end

  let(:raw_post) { params.to_json }
end
