# frozen_string_literal: true

if defined?(Searchkick) && defined?(Elasticsearch::Client)
  Searchkick.client = Elasticsearch::Client.new(
    url: RCreds.fetch(:elastic, :url, default: 'https://localhost:9200'),
    user: RCreds.fetch(:elastic, :user, default: 'elastic'),
    password: RCreds.fetch(:elastic, :password, default: 'changeme'),
    transport_options: Rails.env.development? ? { ssl: { verify: false } } : { ssl: { ca_file: Rails.root.join('elastic.crt') } },
    log: !Rails.env.test?
  )

  Searchkick.index_prefix = [Rails.env, ENV.fetch('TEST_ENV_NUMBER', nil)].compact.join('_')
end
