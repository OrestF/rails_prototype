def source_paths
  [File.expand_path(__dir__)]
end

def add_gems
  gem 'sidekiq'
  gem 'r_creds'
  gem 'oj'
  gem 'blueprinter'
  gem 'pagy'
  gem 'readymade'
  gem 'api-pagination'
  gem 'apitome'
  gem 'rack-cors'
  gem 'rspec_api_documentation'
  gem 'devise-jwt'
  gem 'devise_invitable'
  gem 'xlog'
  gem "image_processing"

  gem_group :development, :test do
    gem 'dotenv'
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
    gem 'rspec-sidekiq'
    gem 'vcr'
    gem 'fakeredis'
    gem 'factory_bot_rails'
    gem 'faker'
    gem 'database_cleaner'
    gem 'webmock'
  end
end

def copy_configs
  copy_file 'config/initializers/blueprinter.rb'
  copy_file 'config/initializers/devise.rb'
  copy_file 'config/initializers/redis.rb'
  copy_file 'config/initializers/rspec_api_documentation.rb'
end

def configure_cors
  environment "config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins '*'
      resource '*', headers: :any, methods: %i[get post put delete options], expose: ['authorization']
    end
  end \n"
end

def configure_sprockets
  insert_into_file(
    'config/application.rb',
    "require 'sprockets/railtie'\n\n",
    before: 'Bundler.require(*Rails.groups)'
  )
end

def configure_tests
  run 'rspec --init'
  copy_file 'config/initializers/rspec_api_documentation.rb'
  directory 'spec'#, force: true
  environment 'config.generators.test_framework = :rspec'
  rails_command 'generate apitome:install'

  insert_into_file(
    'app/assets/config/manifest.js',
    "//= link apitome/application.css
//= link apitome/highlight_themes/default.css
//= link apitome/application.js"
  )
end

def setup_sidekiq
  environment 'config.active_job.queue_adapter = :sidekiq'

  insert_into_file(
    'config/routes.rb',
    "require 'sidekiq/web'\n\n",
    before: 'Rails.application.routes.draw do'
  )

  insert_into_file(
    'config/routes.rb',
    "\n  mount with_admin_auth.call(Sidekiq::Web), at: '/sidekiq'\n\n",
    after: 'get "up" => "rails/health#show", as: :rails_health_check'
  )
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

def stop_spring
  run 'spring stop'
end

# TODO: outdated
# def copy_rubocop
#   copy_file '.rubocop.yml'
# end

def setup_db
  rails_command 'db:prepare'
end

# TODO: outdated
# def copy_docker
#   directory 'docker'
#   copy_file 'docker-compose.yml'
#   copy_file 'docker-compose.development.yml'
# end

# TODO: outdated
# def copy_env
#   copy_file '.env'
#   copy_file '.env.development'
# end

def copy_docs
  copy_file 'README_EXAMPLE.md', 'README.md'
  copy_file 'CHANGELOG_EXAMPLE.md', 'CHANGELOG.md'
  copy_file 'lemme_check_remote.sh'
  # empty_directory 'doc'
end

def configure_xlog
  environment 'config.middleware.use Xlog::Middleware'
end

def setup_abdi
  directory 'infrastructure'

  copy_file 'data/application_record.rb'
  copy_file 'data/current.rb'
  directory 'data/concerns'

  # directory 'data'
  directory 'business'

  # remove_dir 'app/models'

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
  directory 'app/controllers/api/v1/direct_uploads_controller.rb'
  directory 'app/services/direct_uploads'
end

def setup_active_storage
  rails_command 'active_storage:install'
end


def copy_serializers
  directory 'app/serializers'
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
end

def setup_default_url_options
  insert_into_file(
    'config/environments/development.rb',
    "\n  config.action_mailer.default_url_options = { host: 'localhost', port: 3000 } \n",
    after: 'Rails.application.configure do'
  )

  insert_into_file(
    'config/environments/test.rb',
    "\n  config.action_mailer.default_url_options = { host: 'localhost', port: 3000 } \n",
    after: 'Rails.application.configure do'
  )

  insert_into_file(
    'config/environment.rb',
    "Rails.application.default_url_options = Rails.application.config.action_mailer.default_url_options"
  )
end

def setup_users
  setup_default_url_options

  setup_devise

  copy_file 'data/user.rb'

  copy_file 'app/controllers/api/devise/invitations_controller.rb'
  copy_file 'app/controllers/api/devise/sessions_controller.rb'
  copy_file 'app/controllers/api/devise/passwords_controller.rb'
  # TODO: add confirmations_controller.rb
  # TODO: add registrations_controller.rb

  copy_file 'business/users/operations/send_password_restore_email.rb'
  copy_file 'business/users/forms/send_password_restore_email.rb'

  gsub_file 'config/routes.rb', /devise_for :users/, ''

  route "\n  constraints format: :json do
      devise_for :users,
                 path: '/api/v1/users/',
                 controllers: { sessions: 'api/devise/sessions',
                                passwords: 'api/devise/passwords',
                                invitations: 'api/devise/invitations' }
    end\n"
end

def cleanup
  remove_dir 'app/models'
  remove_dir 'spec/models'
end

# Main setup
source_paths

add_gems

after_bundle do
  puts '______________________________________________AFTER_BUNDLE_____________________________________________________'
  # stop_spring

  copy_configs
  setup_routes_auth
  setup_sidekiq
  configure_cors
  configure_sprockets
  configure_tests
  # copy_rubocop
  configure_xlog

  setup_abdi

  copy_docs
  setup_active_storage
  setup_users
  copy_serializers

  setup_db

  cleanup

  # git :init
  # git add: '.'
  # git commit: %q{ -m 'Initial commit' }
  puts '______________________________________________FINISH_____________________________________________________'
end

# TODO
# RCreds.fetch(:devise, :jwt_secret_key)
# RCreds.fetch(:admin, :username)
# RCreds.fetch(:admin, :password)
#