# frozen_string_literal: true

require 'factory_bot_rails'

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  config.include ActionDispatch::TestProcess
end

module SpecFileUploader
  include ActionDispatch::TestProcess
  extend self
end
