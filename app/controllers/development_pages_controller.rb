# frozen_string_literal: true

class DevelopmentPagesController < ActionController::Base
  include AdminBasicAuth

  # Project links on the home page. Fill in the URLs as they appear; blank ones are shown as "not set".
  PROJECT_LINKS = {
    environments: {
      'Staging' => { 'Frontend' => '', 'Backend' => '', 'Portainer' => '' },
      'Production' => { 'Frontend' => '', 'Backend' => '', 'Portainer' => '' }
    },
    integrations: { 'Stripe' => '' },
    useful: { 'JIRA' => '' }
  }.freeze

  DOCS_COMMAND = 'bundle exec rake docs:generate RAILS_ENV=test'

  # http_basic_authenticate_with name: RCreds.fetch(:admin, :username), password: RCreds.fetch(:admin, :password), if: :auth_env?
  before_action :authenticate_admin, only: :open_api_docs

  helper_method :docs_status

  layout 'development_pages'

  def home
    @project_links = PROJECT_LINKS
    @missing_project_links = PROJECT_LINKS[:environments].values.flat_map(&:values)
                                                         .concat(PROJECT_LINKS.except(:environments).values.flat_map(&:values))
                                                         .any?(&:blank?)
  end

  # doc/api/open_api.json is written by DOCS_COMMAND
  def open_api_docs
    unless File.exist?(open_api_file_path)
      return render plain: "OpenAPI file is not generated yet: run `#{DOCS_COMMAND}`", status: :not_found
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

  # Status tag for a file written by DOCS_COMMAND
  def docs_status(path)
    file = Rails.root.join(path)
    return { tone: :warn, label: 'Not generated yet', hint: "Run: #{DOCS_COMMAND}" } unless File.exist?(file)

    { tone: :ok, label: "Generated #{helpers.time_ago_in_words(File.mtime(file))} ago" }
  end
end
