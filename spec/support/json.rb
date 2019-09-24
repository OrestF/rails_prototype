def json
  JSON.parse(response_body || response.body)
end
