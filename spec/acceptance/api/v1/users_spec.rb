# frozen_string_literal: true

require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'v1 Users' do
  header 'Content-Type', 'application/json'

  let!(:user) { create(:user) }

  get '/api/v1/users/profile' do
    let!(:headers) { auth_headers(user) }

    it 'GET profile' do
      headers
      do_request

      expect(response_status).to eq 200
    end
  end

  patch '/api/v1/users/profile' do
    with_options scope: :user do
      render_form_parameters(Users::Forms::Update)
    end

    let(:headers) { auth_headers(user) }

    context 'when params are correct' do
      let(:params) do
        { user: attributes_for(:user) }
      end

      it 'PATCH profile' do
        do_request

        expect(response_status).to eq(200)
      end
    end
  end

  let(:raw_post) { params.to_json }
end
