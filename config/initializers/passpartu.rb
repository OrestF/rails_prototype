# frozen_string_literal: true

Passpartu.configure do |config|
  config.policy_file = './business/permissions.yml'
  config.raise_policy_missed_error = false
  config.check_waterfall = true
end
