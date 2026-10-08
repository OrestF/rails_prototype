# frozen_string_literal: true

class ApidocsController < Apitome::DocsController
  include AdminBasicAuth

  before_action :authenticate_admin
end
