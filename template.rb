require 'uri'
require 'open-uri'

# DEV_MODE=true rails new my_app --api --database=postgresql --skip-test --skip-kamal --skip-thruster --template="rails_prototype/template.rb"

# TODO: add business specs foe existing operations
def source_paths
  [File.expand_path(__dir__)]
end

def download_file(from_path, to_path = from_path)
  # force: template files always replace the generated defaults, without a conflict prompt
  if ENV['DEV_MODE']
    # for local development and upgrades
    copy_file from_path, to_path, force: true
  else
    base_url = 'https://raw.githubusercontent.com/OrestF/rails_prototype/main'
    get([base_url, from_path].join('/'), to_path, force: true)
  end
end

def add_gems
  # Overwrite the whole Gemfile so the generated app matches the house standard:
  # alphabetical (Bundler/OrderedGems), Redis-free, Propshaft assets, no kamal/thruster/vcr/webmock/sweet_staging.
  # Rails is pinned to the generator version so the generated configs match the runtime.
  rails_version = [Rails::VERSION::MAJOR, Rails::VERSION::MINOR, Rails::VERSION::TINY].join('.')

  create_file 'Gemfile', <<~GEMFILE, force: true
    source 'https://rubygems.org'

    gem 'rails', '~> #{rails_version}'

    gem 'action_scope'
    gem 'api-pagination', '~> 6.0' # 7.x references Pagy::OPTIONS, which Pagy 9 does not have
    gem 'apitome'
    gem 'blueprinter'
    gem 'bootsnap', require: false
    gem 'devise_invitable'
    gem 'devise-jwt'
    gem 'exception_notification'
    gem 'file_exists'
    gem 'image_processing'
    gem 'maintenance_tasks'
    gem 'mission_control-jobs'
    gem 'motor-admin'
    gem 'oj'
    gem 'overcommit', require: false # shells out to `git --version` when required
    gem 'pagy', '~> 9.4' # Pagy 43 removed Pagy::Backend (used by Api::BaseController and BaseSearch)
    gem 'passpartu'
    gem 'pg'
    gem 'propshaft'
    gem 'puma'
    gem 'pundit'
    gem 'rack-cors'
    gem 'r_creds'
    gem 'readymade'
    gem 'rspec_api_documentation'
    gem 'solid_cable'
    gem 'solid_cache'
    gem 'solid_queue'
    gem 'tzinfo-data', platforms: %i[ windows jruby ]
    gem 'xlog'

    group :development, :test do
      gem 'brakeman', require: false
      gem 'bundler-audit', require: false
      gem 'byebug'
      gem 'debug', platforms: %i[ mri windows ], require: 'debug/prelude'
      gem 'factory_bot_rails'
      gem 'faker'
      gem 'fasterer'
      gem 'rubocop-rails-omakase', require: false
    end

    group :development do
      gem 'bullet'
      gem 'rubocop'
      gem 'rubocop-performance'
      gem 'rubocop-rspec'
      gem 'rubycritic'
    end

    group :test do
      gem 'database_cleaner'
      gem 'rspec-rails'
      gem 'rspec-retry'
      gem 'simplecov', '~> 0.22.0', require: false # spec/support/simplecov_profile.rb uses the 0.x add_filter/add_group API
    end
  GEMFILE
end

def copy_configs
  download_file 'config/initializers/blueprinter.rb'
  # config/initializers/devise.rb is downloaded in setup_devise, after devise:install
  download_file 'business/permissions.yml'
  download_file 'config/initializers/passpartu.rb'
  download_file 'config/initializers/r_creds.rb'
  # download_file 'config/initializers/redis.rb' # Redis-free: Solid Cache/Queue/Cable instead
  download_file 'config/initializers/flash.rb'
  download_file 'config/initializers/oj.rb'
  # download_file 'config/initializers/searchkick.rb'
  # download_file 'config/initializers/sidekiq.rb'
  download_file 'config/initializers/disable_raise_on_missing_callbacks.rb'
  # download_file 'config/sidekiq.yml'
  # download_file 'config/initializers/rspec_api_documentation.rb'
  download_file 'config/initializers/solid_cache_pg_patch.rb'
end

def configure_cors
  environment "config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins '*'
      resource '*', headers: :any, methods: %i[get post put delete options], expose: ['authorization']
    end
  end \n"
end

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
  download_file 'spec/support/rspec_api_documentation_patches.rb' # OpenAPI writer fixes
  download_file 'spec/support/search.rb'
  download_file 'spec/support/simplecov_profile.rb'
  # download_file 'spec/support/vcr.rb' # VCR/WebMock removed
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

# DEPRECATED: sweet_staging is no longer in the Gemfile; add `gem 'sweet_staging'` back to use it
def setup_sweet_staging
  download_file 'config/initializers/sweet_staging.rb'
end

def setup_rails_performance
  download_file 'config/initializers/rails_performance.rb'
end

# Propshaft serves everything under app/assets/* (and the engines' asset dirs) as is, no manifest needed
def download_assets_directory
  download_file 'app/assets/images/.keep'
  download_file 'app/assets/javascripts/.keep'
  download_file 'app/assets/stylesheets/.keep'
end

def setup_apidocs
  # Generator first: it writes config/initializers/apitome.rb, which is then replaced by ours
  rails_command 'generate apitome:install'
  download_file 'config/initializers/apitome.rb'
  download_file 'config/initializers/rspec_api_documentation.rb'
  download_file 'doc/configurations/api/open_api.yml' # OpenAPI info/host/schemes
  # Propshaft ignores the `require` directives in apitome/application.{css,js},
  # so this layout links bootstrap and the prebuilt apitome bundles directly
  download_file 'app/views/layouts/apitome/application.html.erb'

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

# Production already runs Active Job on Solid Queue (Rails default); development gets the same setup,
# with its own queue database, instead of the in-memory :async adapter. Must run before setup_db.
def setup_solid_queue
  gsub_file 'config/database.yml',
            /^development:\n  <<: \*default\n  database: (\w+)_development\n/,
            <<~'YAML'
              development:
                primary: &primary_development
                  <<: *default
                  database: \1_development
                queue:
                  <<: *primary_development
                  database: \1_development_queue
                  migrations_paths: db/queue_migrate
            YAML

  environment 'config.solid_queue.connects_to = { database: { writing: :queue } }', env: 'development'
  environment 'config.active_job.queue_adapter = :solid_queue', env: 'development'

  # /jobs is mounted behind with_admin_auth (see setup_routes), so the engine's own
  # basic auth (enabled by default, 401 until credentials are configured) is not needed
  environment 'config.mission_control.jobs.http_basic_auth_enabled = false'
end

# Written in one go, after every generator that injects routes (devise, motor, maintenance_tasks):
# single guarded maintenance_tasks mount, admin basic auth only outside local envs, no generator boilerplate.
def setup_routes
  create_file 'config/routes.rb', <<~'RUBY', force: true
    Rails.application.routes.draw do
      constraints format: :json do
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
      end

      with_admin_auth = lambda do |app|
        Rack::Builder.new do
          unless Rails.env.local?
            use Rack::Auth::Basic do |username, password|
              ActiveSupport::SecurityUtils.secure_compare(Digest::SHA256.hexdigest(username),
                                                          Digest::SHA256.hexdigest(RCreds.fetch(:admin, :username))) &
                ActiveSupport::SecurityUtils.secure_compare(Digest::SHA256.hexdigest(password),
                                                            Digest::SHA256.hexdigest(RCreds.fetch(:admin, :password)))
            end
          end
          run app
        end
      end

      mount with_admin_auth.call(MaintenanceTasks::Engine), at: '/maintenance_tasks'
      mount with_admin_auth.call(MissionControl::Jobs::Engine), at: '/jobs'
      mount Motor::Admin => '/motor_admin'

      root to: 'development_pages#home'

      get '/api/docs', to: 'apidocs#index'
      get 'open_api_docs', to: 'development_pages#open_api_docs'
      get 'up' => 'rails/health#show', as: :rails_health_check
    end
  RUBY
end

def setup_controllers
  download_file 'app/controllers/api/devise/invitations_controller.rb'
  download_file 'app/controllers/api/devise/passwords_controller.rb'
  download_file 'app/controllers/api/devise/sessions_controller.rb'

  download_file 'app/controllers/api/v1/base_controller.rb'
  download_file 'app/controllers/api/v1/direct_uploads_controller.rb'
  download_file 'app/controllers/api/base_controller.rb'

  download_file 'app/controllers/concerns/admin_basic_auth.rb'
  download_file 'app/controllers/concerns/authorizer.rb'
  download_file 'app/controllers/concerns/error_handler.rb'

  download_file 'app/controllers/apidocs_controller.rb'
  download_file 'app/controllers/development_pages_controller.rb'
end

def setup_pundit
  generate 'pundit:install'
  download_file 'app/policies/application_policy.rb'
end

def setup_db
  rails_command 'db:prepare'
end

def copy_docker
  # download_file 'nginx/staging.conf'    # not present in the source repo (404)
  # download_file 'nginx/production.conf' # not present in the source repo (404)

  download_file 'docker-compose.test.yml'
  download_file 'docker-compose.yml'
  download_file 'docker-entrypoint.sh'
  download_file 'docker-entrypoint.test.sh'
  download_file 'docker-entrypoint-anycable.sh'
  download_file 'docker-entrypoint-jobs.sh'
  # With setup_sidekiq, the jobs entrypoint runs Sidekiq instead and keeps its name:
  # gsub_file 'docker-entrypoint-jobs.sh', 'bundle exec bin/jobs', 'bundle exec sidekiq -C config/sidekiq.yml'
  download_file 'Dockerfile'
  download_file '.env.example', '.env'
  download_file '.env.test' # committed, test-only: CI copies it to stack.env

  # Downloads are written as 644, but git must store the entrypoints as 755: the bind mount (.:/var/www) hides
  # the image's chmod, and CI checks them out with their git mode
  %w[docker-entrypoint.sh docker-entrypoint.test.sh docker-entrypoint-anycable.sh docker-entrypoint-jobs.sh].each do |entrypoint|
    chmod entrypoint, 0o755
  end

  # The image runs the Ruby the app was generated with
  gsub_file 'Dockerfile', %r{^FROM --platform=linux/amd64 ruby:.*$}, "FROM --platform=linux/amd64 ruby:#{RUBY_VERSION}"
  %w[.env .env.test].each do |env_file|
    gsub_file env_file, /^RUBY_VERSION=$/, "RUBY_VERSION=#{RUBY_VERSION}"
    gsub_file env_file, /^APP_NAME=$/, "APP_NAME=#{app_name}"
  end
end

# Containers reach the postgres service through POSTGRES_* (stack.env); local runs get nil from RCreds and keep
# using the socket
def configure_database_env
  postgres_env = <<~'YAML'.gsub(/^/, '  ')
    # Containers reach the postgres service through POSTGRES_* (stack.env); local runs get nil and use the socket
    username: <%= RCreds.fetch(:postgres, :user) %>
    password: <%= RCreds.fetch(:postgres, :password) %>
    host: <%= RCreds.fetch(:postgres, :host) %>
    port: <%= RCreds.fetch(:postgres, :port) %>
  YAML
  inject_into_file 'config/database.yml', postgres_env, after: /^  (?:max_connections|pool): .*\n/
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
  # download_file 'data/concerns/users/searchable.rb' # DEPRECATED
  # download_file 'data/concerns/searchable.rb' # DEPRECATED
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
  # Inlined (was `template 'kamal-secrets.tt'`): a remote template has no local source_paths to render from
  create_file '.kamal/secrets', "#{SecureRandom.hex(64)}\n", force: true
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
  download_file 'app/views/development_pages/_tool_card.html.erb'
  download_file 'app/views/development_pages/_chips.html.erb'
  download_file 'app/views/development_pages/_icon.html.erb'
  download_file 'app/views/layouts/development_pages.html.erb'
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
  # API devise routes are written in setup_routes
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
  # The generator also mounts the engine without auth; setup_routes replaces that with a guarded mount
  generate 'maintenance_tasks:install'
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

  puts '______________________________________________API DOCS____________________________________________________________'
  puts <<-TEXT
  Acceptance specs (spec/acceptance) generate the API docs, after the credentials above are set:
    bundle exec rake docs:generate RAILS_ENV=test
  It writes doc/api/*.json for Apitome (/api/docs) and doc/api/open_api.json (Swagger 2.0),
  which is downloadable from the home page (/open_api_docs).
  TEXT

  puts '______________________________________________BACKGROUND JOBS_____________________________________________________'
  puts <<-TEXT
  Active Job runs on Solid Queue (development and production). Start a worker with:
    bin/jobs
  or run it inside Puma:
    SOLID_QUEUE_IN_PUMA=1 bin/rails server
  Jobs dashboard: /jobs
  TEXT

  puts '______________________________________________MOTOR ADMIN_____________________________________________________'
  puts <<-TEXT
  IMPORTANT!
  In order to secure MotorAdmin, you need to specify environment variables on your servers:
  MOTOR_AUTH_USERNAME
  MOTOR_AUTH_PASSWORD
  TEXT
end

def setup_house_style
  create_file '.rubocop.yml', <<~YAML, force: true
    inherit_gem: { rubocop-rails-omakase: rubocop.yml }

    plugins:
      - rubocop-rspec
      - rubocop-performance

    AllCops:
      NewCops: enable
      SuggestExtensions: false
      Exclude:
        - bin/*
        - db/schema.rb
        - data/concerns/readymade/**/*
        - '**/vendor/**/*'
        - '**/gems/**/*'
      TargetRubyVersion: #{RUBY_VERSION}


    # ====== Metrics ======

    Metrics/MethodLength:
      Max: 50
      Exclude:
        - db/migrate/**/*

    Metrics/AbcSize:
      Exclude:
        - db/migrate/**/*
        - infrastructure/blueprint_policy_extractor.rb

    Metrics/CyclomaticComplexity:
      Exclude:
        - infrastructure/blueprint_policy_extractor.rb

    Metrics/PerceivedComplexity:
      Exclude:
        - infrastructure/blueprint_policy_extractor.rb

    Metrics/BlockLength:
      Exclude:
        - spec/acceptance/**/*
        - spec/business/**/*
        - spec/data/**/*
        - config/**/*.rb
        - config/routes.rb
        - spec/**/*
        - lib/**/*
        - data/concerns/**/*
        - db/**/*

    Metrics/ModuleLength:
      Exclude:
        - data/concerns/**/*

    Metrics/ClassLength:
      Max: 120


    # ====== Style ======

    Style/HashSyntax:
      Enabled: false

    Style/ClassAndModuleChildren:
      Enabled: false

    Style/Proc:
      Enabled: false

    Style/SymbolProc:
      Exclude:
        - app/serializers/**/*

    Style/RedundantSelfAssignment:
      Enabled: false

    Style/StringLiterals:
      EnforcedStyle: single_quotes
      Exclude:
        - db/schema.rb
        - db/queue_schema.rb
        - db/cache_schema.rb

    Style/IfUnlessModifier:
      Enabled: false

    Style/FileWrite:
      Enabled: false

    Style/Documentation:
      Enabled: false

    Style/SafeNavigationChainLength:
      Max: 5

    Style/EmptyStringInsideInterpolation:
      Enabled: false

    Style/RedundantLineContinuation:
      Enabled: false

    Style/WordArray:
      Exclude:
        - db/queue_schema.rb
        - db/cache_schema.rb

    Style/FrozenStringLiteralComment:
      Exclude:
        - db/queue_schema.rb
        - db/cache_schema.rb

    Bundler/OrderedGems:
      Enabled: true


    # ====== Other ======

    Layout/LineLength:
      Max: 140
      Exclude:
        - config/initializers/**/*
        - config/routes.rb
        - config/routes/*.rb
        - spec/**/**/*

    Naming/MemoizedInstanceVariableName:
      Enabled: false

    Naming/PredicateMethod:
      Enabled: false

    Performance/Count:
      Enabled: false

    Lint/MissingSuper:
      Enabled: false

    # ====== RSpec ======

    RSpec/EmptyExampleGroup:
      Enabled: false

    RSpec/HookArgument:
      Enabled: false

    RSpec/ScatteredLet:
      Enabled: false

    RSpec/AnyInstance:
      Enabled: false

    RSpec/IndexedLet:
      Enabled: false

    RSpec/ExampleLength:
      Max: 25

    RSpec/LetSetup:
      Enabled: false

    RSpec/NestedGroups:
      Enabled: false

    RSpec/ContextWording:
      Exclude:
        - spec/data/**/*
        - spec/support/shared_contexts/*
        - spec/support/shared_contexts/**/*

    RSpec/MessageSpies:
      Enabled: false

    RSpec/MultipleExpectations:
      Enabled: false

    RSpec/MultipleMemoizedHelpers:
      Enabled: false

    RSpec/Output:
      Exclude:
        - spec/spec_helper.rb
  YAML

  create_file '.overcommit.yml', <<~'YAML', force: true
    verify_signatures: false

    PreCommit:
      ALL:
        exclude:
          - 'node_modules/**/*'

      AuthorName:
        enabled: false

      AuthorEmail:
        enabled: false

      BundlerAudit:
        enabled: true
        description: 'Check for vulnerable versions of gems'
        required_executable: 'bundler-audit'
        command: ['bundle', 'exec', 'bundler-audit', 'check']
        flags:   ['--update']
        on_fail: 'warn'

      Brakeman:
        enabled: true
        description: 'Check for security vulnerabilities'
        required_executable: 'brakeman'
        command: ['bundle', 'exec', 'brakeman', '--skip-files', 'app/controllers/pages_controller.rb']
        flags: ['--exit-on-warn', '--except', 'MassAssignment,PermitAttributes,SendFile']

      Fasterer:
        enabled: true
        description: 'Analyzing for potential speed improvements'
        required_executable: 'fasterer'
        command: ['bundle', 'exec', 'fasterer']
        include: '**/*.rb'

      RuboCop:
        enabled: true
        description: 'Analyze with RuboCop'
        required_executable: 'rubocop'
        command: ['bundle', 'exec', 'rubocop']
        include:
          - '**/*.gemspec'
          - '**/*.rake'
          - '**/*.rb'
          - '**/*.ru'
          - '**/Gemfile'
          - '**/Rakefile'

    #PrePush:
    #  RSpec:
    #    enabled: true
    #    description: 'Run RSpec test suite'
    #    required_executable: 'rspec'
    #    command: ['bundle', 'exec', 'rspec']


    PreRebase:
      MergedCommits:
        enabled: false
  YAML

  append_to_file '.gitignore', <<~'GITIGNORE'

    # Ignore key files for decrypting credentials and more.
    /config/credentials/*.key

    # Ignore precompiled assets (Propshaft writes them to public/assets).
    /public/assets

    # SimpleCov output
    /coverage/

    # Committed test-only environment for CI (CI copies it to stack.env); stack.env itself is local
    !/.env.test
    stack.env
  GITIGNORE
end

# Main setup
source_paths

add_gems

after_bundle do
  copy_configs
  setup_controllers
  setup_pundit
  download_policies_folder
  # setup_sidekiq
  configure_cors
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

  configure_database_env
  setup_solid_queue
  setup_db
  setup_motor_admin
  setup_maintenance_tasks
  # setup_sweet_staging # DEPRECATED
  # setup_rails_performance # needs Redis

  setup_routes

  copy_docker

  cleanup

  # generate_api_docs # optional

  setup_default_url_options

  setup_house_style

  # Normalize the whole tree to the house style (non-fatal)
  run 'bundle exec rubocop -A'

  post_setup_message
end
