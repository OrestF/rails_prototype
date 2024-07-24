# frozen_string_literal: true

if defined?(Searchkick)
  RSpec.configure do |config|
    config.around do |example|
      if example.metadata[:search_index]
        example.run
      else
        Searchkick.callbacks(false) { example.run }
      end
    end
  end

  # remove annoying warning in specs
  module Searchkick
    def self.warn(message)
      return if message.include?('Records in search index do not exist in database')

      super("[searchkick] WARNING: #{message}")
    end
  end
end
