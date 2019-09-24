def auth_headers(user)
  headers = { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }
  Devise::JWT::TestHelpers.auth_headers(headers, user)
end
