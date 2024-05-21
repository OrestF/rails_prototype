# frozen_string_literal: true

require 'rails_helper'

resource 'v1 Users > Authentication' do
  header 'Content-Type', 'application/json'

  let(:user) { create(:user) }

  post '/api/v1/users/password' do
    with_options scope: :user, required: true do
      render_form_parameters(Users::Forms::SendPasswordRestoreEmail)
    end

    let(:params) do
      { user: { email: email, accept_password_url: Faker::Internet.url } }
    end

    let(:mail) { ActionMailer::Base.deliveries.last }

    context 'with valid params' do
      let(:email) { user.email }

      it 'POST passwords' do
        explanation 'Forgot password'

        do_request

        expect(response_status).to eq 200
        expect(mail.subject).to eq('Reset password instructions')
      end
    end

    context 'with invalid params' do
      let(:email) { nil }

      it 'POST passwords [invalid]', document: false do
        do_request
        expect(response_status).to eq 404
        expect(mail).to be_nil
      end
    end
  end

  patch '/api/v1/users/password' do
    with_options scope: :user, required: true do
      parameter :reset_password_token, required: true
      parameter :password, required: true
      parameter :password_confirmation, required: true
    end

    before do
      @raw, enc = Devise.token_generator.generate(User, :reset_password_token)
      user.reset_password_token = enc
      user.reset_password_sent_at = Time.current
      user.save(validate: false)
    end

    let(:params) do |ex|
      { user: { reset_password_token: @raw,
                password: 'new_password',
                password_confirmation: ex.metadata[:password_confirmation] } }
    end

    context 'with valid params', password_confirmation: 'new_password' do
      it 'PATCH password' do
        do_request

        expect(response_status).to eq 200
      end
    end

    context 'with invalid params', password_confirmation: 'old_password' do
      it 'PATCH password [invalid]', document: false do
        do_request

        expect(response_status).to eq 400
      end
    end
  end

  let(:raw_post) { params.to_json }
end
