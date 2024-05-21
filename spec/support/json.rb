# frozen_string_literal: true

def response_json
  JSON.parse(response_body || response.body)
end
