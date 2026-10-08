# frozen_string_literal: true

class DevelopmentPagesController < ActionController::Base
  include AdminBasicAuth

  # http_basic_authenticate_with name: RCreds.fetch(:admin, :username), password: RCreds.fetch(:admin, :password), if: :auth_env?
  before_action :authenticate_admin, only: :open_api_docs

  layout 'development_pages'

  def home
  end

  # doc/api/open_api.json is written by `bundle exec rake docs:generate RAILS_ENV=test`
  def open_api_docs
    unless File.exist?(open_api_file_path)
      return render plain: 'OpenAPI file is not generated yet: run `bundle exec rake docs:generate RAILS_ENV=test`',
                    status: :not_found
    end

    send_file open_api_file_path, filename: 'open_api.json', type: 'application/json', disposition: 'attachment'
  end

  private

  def auth_env?
    !Rails.env.local?
  end

  def open_api_file_path
    Rails.root.join('doc/api/open_api.json')
  end
end
