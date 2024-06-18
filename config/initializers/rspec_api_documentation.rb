# frozen_string_literal: true

require 'rspec'
# Fix issue with endpoints that use send_data
# [binary data] in response_body error fix
# https://github.com/zipmark/rspec_api_documentation/issues/456
module RspecApiDocumentation

  class ClientBase
    private

    def read_request_body
      input = last_request.env["rack.input"]
      input.try(:rewind)
      input.try(:read) || {}.to_json
    end
  end

  class RackTestClient < ClientBase
    def response_body
      if %w[json csv].any? { |f| last_response.headers['Content-Type'].to_s.include?(f) }
        last_response.body.encode('utf-8')
      else
        '[binary data]'
      end
    end

    # FIX FOR
    # Rack::Test::Error: No response yet. Request a page first
    # if u have :status parameter
    def response_status
      last_response.status
    end
  end
end

RspecApiDocumentation.configure do |config|
  # Output folder
  config.docs_dir = Rails.root.join('./doc/api')

  # An array of output format(s).
  # Possible values are :json, :html, :combined_text, :combined_json,
  #   :json_iodocs, :textile, :markdown, :append_json
  config.format = %i[json]

  # Change how the post body is formatted by default, you can still override by `raw_post`
  # Can be :json, :xml, or a proc that will be passed the params
  config.request_body_formatter = [:json]

  # Removes the DSL method `status`, this is required if you have a parameter named status
  # In this case you can assert response status with `expect(response_status).to eq 200`
  config.disable_dsl_status!
end
