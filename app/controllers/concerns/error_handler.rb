# frozen_string_literal: true

module ErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from StandardError do |e|
      handle_errors(e)
    end
  end

  private

  def handle_errors(error)
    if error.instance_of?(ActiveRecord::RecordNotFound)
      return error_response('Not Found', "#{error.model} not found", 404)
    end
    return error_response('Forbidden', error.message, 403) if error.instance_of?(Pundit::NotAuthorizedError)

    raise error if live_env?

    message, backtrace = live_env? ? ['', ''] : [error.message, error.backtrace.first(10).join("\n")]
    error_response('Internal Server Error', message, 500, backtrace)
  end

  def error_response(status, message, code, backtrace = '')
    render json: { status: status, message: message, code: code, backtrace: backtrace }, status: code
  end

  def live_env?
    return false if Rails.env.staging?

    !Rails.env.local?
  end
end
