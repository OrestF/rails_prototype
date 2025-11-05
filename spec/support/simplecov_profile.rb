# frozen_string_literal: true

SimpleCov.profiles.define 'abdi' do
  load_profile 'test_frameworks'
  add_filter '/config/'
  add_filter '/app/models/'
  add_filter '/app/helpers/'
  add_filter '/app/channels/'
  add_filter '/app/mailers/'
  add_filter '/app/policies/'
  add_filter '/app/jobs/'
  add_filter '/app/controllers/concerns/'
  add_filter 'app/controllers/api_controller.rb'
  add_filter 'app/controllers/apidocs_controller.rb'
  add_filter 'app/controllers/application_controller.rb'

  add_group 'App', 'app'
  add_group 'Business', 'business'
  add_group 'Data', 'data'
end

module SimpleCov::Configuration
  def clean_filters
    @filters = []
  end
end

SimpleCov.configure do
  clean_filters

  load_profile 'abdi'
end

require 'simplecov_json_formatter'
SimpleCov.formatter = SimpleCov::Formatter::JSONFormatter

SimpleCov.start 'abdi'
