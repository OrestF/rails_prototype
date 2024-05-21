# frozen_string_literal: true

require 'rspec/retry'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  # config.before do
  #   allow(Searchable).to receive(:searchable_callbacks).and_return(:inline) # does not work in tests
  # end

  # config.before { Current.user = nil }
end

RSpec.configure do |config|
  # show retry status in spec process
  config.verbose_retry = true
  # show exception that triggers a retry if verbose_retry is set to true
  config.display_try_failure_messages = true

  # run retry only on features
  config.around :each do |ex|
    ex.run_with_retry retry: 3
  end

  # callback to be run between retries
  config.retry_callback = proc do |ex|
    puts "Exception: #{ex.inspect} #{ex.display_exception}"
    # run some additional clean up task - can be filtered by example metadata
    DatabaseCleaner.clean
  end
end
