require 'uri'
require 'open-uri'

# DEV_MODE=true rails new rvmd --database=postgresql --css=tailwind --skip-javascript --skip-sprockets --template="rails_prototype/template.rb" --skip-kamal

# TODO: add business specs foe existing operations
def source_paths
  [File.expand_path(__dir__)]
end

def download_file(from_path, to_path = from_path)
  if ENV['DEV_MODE']
    # for local development and upgrades
    copy_file from_path, to_path
  else
    base_url = 'https://raw.githubusercontent.com/OrestF/rails_prototype/rails_api'
    get([base_url, from_path].join('/'), to_path)
  end
end

def add_gems
  # gem 'sidekiq'
  # gem 'sidekiq-cron'
  # gem 'sidekiq-failures'
  gem 'r_creds'
  gem 'oj'
  gem 'blueprinter'
  gem 'pagy'
  gem 'readymade'
  gem 'api-pagination'
  gem 'apitome'
  # gem 'sprockets-rails', :require => 'sprockets/railtie'
  gem 'rack-cors'
  gem 'rspec_api_documentation'
  gem 'devise-jwt'
  gem 'devise_invitable'
  gem 'xlog'
  # gem "image_processing"
  gem 'pundit'
  gem 'passpartu'

  gem 'file_exists'
  gem 'motor-admin'
  gem 'maintenance_tasks'
  gem 'sweet_staging'
  gem 'rails_performance'

  gem 'elasticsearch'
  gem 'searchkick'

  gem "mission_control-jobs"

  gem_group :development, :test do
    # gem 'dotenv'
    gem 'byebug'
  end

  gem_group :development do
    gem 'rubocop'
    gem 'rubycritic'
    gem 'brakeman'
    gem 'bullet'
  end

  gem_group :test do
    gem 'rspec-retry'
    gem 'simplecov'
    gem 'rspec-rails', '~> 4.0', '>= 4.0.1'
    # gem 'rspec-sidekiq'
    gem 'vcr'
    gem 'fakeredis'
    gem 'factory_bot_rails'
    gem 'faker'
    gem 'database_cleaner'
    gem 'webmock'
  end
end

def copy_configs
  download_file 'config/initializers/blueprinter.rb'
  download_file 'config/initializers/devise.rb'
  download_file 'business/permissions.yml'
  download_file 'config/initializers/passpartu.rb'
  download_file 'config/initializers/r_creds.rb'
  download_file 'config/initializers/redis.rb'
  download_file 'config/initializers/flash.rb'
  download_file 'config/initializers/oj.rb'
  download_file 'config/initializers/searchkick.rb'
  # download_file 'config/initializers/sidekiq.rb'
  download_file 'config/initializers/disable_raise_on_missing_callbacks.rb'
  # download_file 'config/sidekiq.yml'
  # download_file 'config/initializers/rspec_api_documentation.rb'
end

def configure_cors
  environment "config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins '*'
      resource '*', headers: :any, methods: %i[get post put delete options], expose: ['authorization']
    end
  end \n"
end

# def configure_sprockets
#   insert_into_file(
#     'config/application.rb',
#     "require 'sprockets/railtie'\n\n",
#     before: 'Bundler.require(*Rails.groups)'
#   )
# end

def download_spec_acceptance_directory
  download_file 'spec/acceptance/api/devise/invitations_spec.rb'
  download_file 'spec/acceptance/api/devise/passwords_spec.rb'
  download_file 'spec/acceptance/api/devise/registrations_spec.rb'
  download_file 'spec/acceptance/api/devise/sessions_spec.rb'

  download_file 'spec/acceptance/api/v1/users_spec.rb'
end

def download_spec_support_directory
  download_file 'spec/support/auth.rb'
  download_file 'spec/support/database_cleaner.rb'
  download_file 'spec/support/factory_bot.rb'
  # download_file 'spec/support/fakeredis.rb' # invalid file configuration
  download_file 'spec/support/form_parameters.rb'
  download_file 'spec/support/json.rb'
  download_file 'spec/support/search.rb'
  download_file 'spec/support/simplecov_profile.rb'
  download_file 'spec/support/vcr.rb'
end

def download_spec_factories_directory
  download_file 'spec/factories/user.rb'
end

def download_spec_directory
  download_file 'spec/rails_helper.rb'
  download_file 'spec/spec_helper.rb'

  download_spec_acceptance_directory
  download_spec_factories_directory
  download_spec_support_directory
end

def configure_tests
  run 'rspec --init'

  download_spec_directory

  environment 'config.generators.test_framework = :rspec'
end

def setup_sweet_staging
  download_file 'config/initializers/sweet_staging.rb'
end

def setup_rails_performance
  download_file 'config/initializers/rails_performance.rb'
end

def download_assets_directory
  download_file 'app/assets/config/manifest.js'
  download_file 'app/assets/images/.keep'
  download_file 'app/assets/javascripts/.keep'
  download_file 'app/assets/stylesheets/.keep'
end

def setup_apidocs
  download_file 'config/initializers/rspec_api_documentation.rb'
  download_file 'app/assets/config/manifest.js'
  rails_command 'generate apitome:install'
  insert_into_file(
    'app/assets/config/manifest.js',
    "//= link apitome/application.css
//= link apitome/highlight_themes/default.css
//= link apitome/application.js"
  )

  route "get '/api/docs', to: 'apidocs#index'"
  download_file 'app/controllers/apidocs_controller.rb'
end

# def setup_sidekiq
#   environment 'config.active_job.queue_adapter = :sidekiq'
#
#   insert_into_file(
#     'config/routes.rb',
#     "require 'sidekiq/web'\n\n",
#     before: 'Rails.application.routes.draw do'
#   )
#
#   insert_into_file(
#     'config/routes.rb',
#     "\n  mount with_admin_auth.call(Sidekiq::Web), at: '/sidekiq'\n\n",
#     after: 'get "up" => "rails/health#show", as: :rails_health_check'
#   )
# end

def setup_solid_queue
  route "\n  mount MissionControl::Jobs::Engine, at: '/jobs'\n\n"

  # TODO: Setup mission control jobs initializer
  # rails mission_control:jobs:authentication:configure
  # rails_command 'mission_control:jobs:authentication:configure'
end

def setup_routes_auth
  insert_into_file(
    'config/routes.rb',
    "\n  with_admin_auth = lambda do |app|
    Rack::Builder.new do
      use Rack::Auth::Basic do |username, password|
        ActiveSupport::SecurityUtils.secure_compare(Digest::SHA256.hexdigest(username), Digest::SHA256.hexdigest(RCreds.fetch(:admin, :username))) &
          ActiveSupport::SecurityUtils.secure_compare(Digest::SHA256.hexdigest(password), Digest::SHA256.hexdigest(RCreds.fetch(:admin, :password)))
      end
      run app
    end
  end\n",
    after: 'Rails.application.routes.draw do'
  )
end

def setup_controllers
  download_file 'app/controllers/api/devise/invitations_controller.rb'
  download_file 'app/controllers/api/devise/passwords_controller.rb'
  download_file 'app/controllers/api/devise/sessions_controller.rb'

  download_file 'app/controllers/api/v1/base_controller.rb'
  download_file 'app/controllers/api/v1/direct_uploads_controller.rb'
  download_file 'app/controllers/api/base_controller.rb'

  download_file 'app/controllers/concerns/authorizer.rb'
  download_file 'app/controllers/concerns/error_handler.rb'

  download_file 'app/controllers/apidocs_controller.rb'
  download_file 'app/controllers/development_pages_controller.rb'
end

def setup_pundit
  download_file 'app/assets/config/manifest.js' # fix
  generate 'pundit:install'
  download_file 'app/policies/application_policy.rb'
end

def setup_db
  rails_command 'db:prepare'
end

def copy_docker
  download_file 'nginx/staging.conf'
  download_file 'nginx/production.conf'

  download_file 'docker-compose.test.yml'
  download_file 'docker-compose.yml'
  download_file 'docker-entrypoint.sh'
  download_file 'docker-entrypoint.test.sh'
  download_file 'docker-entrypoint-anycable.sh'
  download_file 'docker-entrypoint-jobs.sh'
  # download_file 'docker-entrypoint-sidekiq.sh'
  download_file 'Dockerfile'
  download_file '.env.example', '.env'
end

def copy_docs
  download_file 'README_EXAMPLE.md', 'README.md'
  download_file 'CHANGELOG_EXAMPLE.md', 'CHANGELOG.md'
  download_file 'lemme_check_remote.sh'
  empty_directory '.docs'
end

def configure_xlog
  environment 'config.middleware.use Xlog::Middleware'
end

def download_infrastructure_folder
  download_file 'infrastructure/base_forms/destroy.rb'

  download_file 'infrastructure/base_operations/destroy.rb'
  download_file 'infrastructure/base_operations/save.rb'

  download_file 'infrastructure/base_action.rb'
  download_file 'infrastructure/base_form.rb'
  download_file 'infrastructure/base_operation.rb'
  download_file 'infrastructure/base_response.rb'
  download_file 'infrastructure/base_search.rb'
  download_file 'infrastructure/blueprint_policy_extractor.rb'
end

def download_policies_folder
  download_file 'app/policies/application_policy.rb'
  download_file 'app/policies/user_policy.rb'
end

def download_data_folder
  download_file 'data/application_record.rb'
  download_file 'data/current.rb'
  download_file 'data/user.rb'

  download_file 'data/concerns/users/temporary_data.rb'
  download_file 'data/concerns/users/searchable.rb'
  download_file 'data/concerns/searchable.rb'
end

def download_business_folder
  download_file 'business/users/forms/send_password_restore_email.rb'
  download_file 'business/users/forms/update.rb'

  download_file 'business/users/operations/send_password_restore_email.rb'
  download_file 'business/users/operations/update.rb'

  download_file 'business/permissions.yml'
end

def setup_abdi
  download_business_folder
  download_data_folder
  download_infrastructure_folder

  insert_into_file(
    'config/application.rb',
    %q(
    config.paths.add 'data', eager_load: true
    config.paths.add 'data/concerns', eager_load: true
    config.paths.add 'business', eager_load: true
    config.paths.add 'infrastructure', eager_load: true
    ),
    after: 'class Application < Rails::Application'
  )
end

def setup_direct_uploads
  download_file 'app/controllers/api/v1/direct_uploads_controller.rb'

  download_file 'app/services/direct_uploads/forms/base.rb'
  download_file 'app/services/direct_uploads/operations/create.rb'
  download_file 'app/services/direct_uploads/operations/destroy.rb'
end

def setup_kamal
  template 'kamal-secrets.tt', '.kamal/secrets'
end

def download_services_folder
  # download_file 'app/services/direct_uploads/forms/base.rb'
  # download_file 'app/services/direct_uploads/operations/create.rb'
  # download_file 'app/services/direct_uploads/operations/destroy.rb'

  download_file 'app/services/search/users.rb'
end

def setup_active_storage
  rails_command 'active_storage:install'
end

def download_serializers_folder
  download_file 'app/serializers/application_serializer.rb'
  download_file 'app/serializers/blob_serializer.rb'
  download_file 'app/serializers/user_serializer.rb'
end

def setup_devise_invitable
  rails_command 'generate devise_invitable:install'
  rails_command 'generate devise_invitable User'
end

def setup_devise_jti_strategy
  generate 'migration', 'AddJtiToUsers', 'jti:string:uniq'
end

def setup_devise_lockable
  generate 'migration', 'AddLockableToUsers', 'failed_attempts:integer', 'unlock_token:string', 'locked_at:datetime'
end

def setup_devise
  rails_command 'generate devise:install'
  rails_command 'generate devise User'
  setup_devise_jti_strategy
  setup_devise_invitable
  setup_devise_lockable

  download_file 'config/initializers/devise.rb'
end

def setup_default_url_options
  environment 'config.action_mailer.default_url_options = { host: "localhost", port: 3000 }', env: 'development'
  environment 'config.action_mailer.default_url_options = { host: "localhost", port: 3000 }', env: 'test'
  environment 'config.action_controller.raise_on_missing_callback_actions = false', env: 'development'
  environment 'config.action_controller.raise_on_missing_callback_actions = false', env: 'test'

  insert_into_file(
    'config/environment.rb',
    "Rails.application.default_url_options = Rails.application.config.action_mailer.default_url_options"
  )
end

def setup_home_page
  download_file 'app/controllers/development_pages_controller.rb'
  download_file 'app/views/development_pages/home.html.erb'
  download_file 'app/views/layouts/development_pages.html.erb'
  route "root to: 'development_pages#home'"
end

def setup_users
  setup_default_url_options

  setup_devise

  download_file 'data/user.rb'

  download_file 'app/controllers/api/devise/invitations_controller.rb'
  download_file 'app/controllers/api/devise/sessions_controller.rb'
  download_file 'app/controllers/api/devise/passwords_controller.rb'
  download_file 'app/controllers/api/devise/registrations_controller.rb'

  download_file 'app/controllers/api/v1/users_controller.rb' # TODO: refactor files copying
  # TODO: add confirmations_controller.rb

  download_file 'business/users/operations/send_password_restore_email.rb'
  download_file 'business/users/forms/send_password_restore_email.rb'

  gsub_file 'config/routes.rb', /devise_for :users/, ''

  route "\n  constraints format: :json do
      devise_for :users,
                 path: '/api/v1/users/',
                 controllers: { sessions: 'api/devise/sessions',
                                passwords: 'api/devise/passwords',
                                registrations: 'api/devise/registrations',
                                invitations: 'api/devise/invitations' }
    end

namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :users, only: %i[] do
        collection do
          get :profile
          patch :profile, to: 'users#update_profile'
        end
      end
    end
  end\n"
end

def cleanup
  remove_dir 'app/models'
  remove_dir 'spec/models'
end

def generate_api_docs
  run 'rake docs:generate RAILS_ENV=test'
end

def setup_motor_admin
  rails_command 'motor:install'
  rails_command 'db:migrate'

  puts <<-TEXT
  IMPORTANT!
  In order to secure MotorAdmin, you need to specify environment variables on your servers:
  MOTOR_AUTH_USERNAME
  MOTOR_AUTH_PASSWORD
  TEXT
end

def setup_maintenance_tasks
  generate 'maintenance_tasks:install'

  insert_into_file(
    'config/routes.rb',
    "\n  mount with_admin_auth.call(MaintenanceTasks::Engine), at: '/maintenance_tasks'\n\n",
    after: 'get "up" => "rails/health#show", as: :rails_health_check'
  )
end

def post_setup_message
  puts '______________________________________________SETUP CREDENTIALS_____________________________________________________'
  jwt_secret_key = SecureRandom.hex(64)
  puts <<-TEXT
  1. cd <my_app_name>
  2. Setup development credentials:
    EDITOR=nano rails credentials:edit --environment development
  
admin:
  username: admin
  password: superSecureAdminPassword
devise:
  jwt_secret_key: #{jwt_secret_key} 
  
  3. To copy development credentials and key for test env, run next commands:
    cp config/credentials/development.yml.enc config/credentials/test.yml.enc
    cp config/credentials/development.key config/credentials/test.key
  TEXT

  puts '______________________________________________MOTOR ADMIN_____________________________________________________'
  puts <<-TEXT
  IMPORTANT!
  In order to secure MotorAdmin, you need to specify environment variables on your servers:
  MOTOR_AUTH_USERNAME
  MOTOR_AUTH_PASSWORD
  TEXT
end

# Main setup
source_paths

add_gems

after_bundle do
  copy_configs
  setup_controllers
  setup_pundit
  download_policies_folder
  setup_routes_auth
  # setup_sidekiq
  configure_cors
  # configure_sprockets # migrate to propshaft
  download_assets_directory
  configure_tests
  setup_apidocs
  configure_xlog
  setup_kamal

  setup_abdi

  copy_docs
  setup_active_storage
  setup_users
  download_serializers_folder
  download_services_folder
  setup_home_page

  setup_db
  setup_motor_admin
  setup_maintenance_tasks
  setup_sweet_staging
  setup_rails_performance

  copy_docker

  cleanup

  # generate_api_docs # optional

  setup_default_url_options

  post_setup_message
end
