# frozen_string_literal: true

class BaseAction
  class NonKeywordArgumentsError < StandardError; end

  def self.call(*args, &block)
    new(*args, &block).call
  end

  attr_reader :args, :data
  def initialize(**args)
    raise NonKeywordArgumentsError if args.present? && !args.is_a?(Hash)

    @args = @data = args

    @args.each do |name, value|
      instance_variable_set("@#{name}", value)
    end

    yield if block_given?
  end

  def call; end

  def response(status, *args)
    BaseResponse.new(status, *args)
  end
end
