def source_paths
  [File.expand_path(__dir__)]
end

def add_gems
  gem 'sidekiq'
  gem 'r_creds'
  gem 'redis'
  gem 'oj'
  gem 'blueprinter'
  gem 'pagy'
  gem 'readymade'
  gem 'api-pagination'
  gem 'apitome'
  gem 'rack-cors'
  gem 'rspec_api_documentation'
  gem 'devise-jwt'
  gem 'xlog'

  gem_group :development, :test do
    gem 'dotenv'
  end

  gem_group :development do
    gem 'rubocop'
    gem 'rubycritic'
    gem 'brakeman'
    gem 'bullet'
  end

  gem_group :test do
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

def copy_templates
  directory 'config'
  copy_file 'bin/setup'
  copy_file 'app/assets/config/manifest.js'
end

def configure_cors
  environment "config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins '*'
      resource '*', headers: :any, methods: [:get, :post, :put, :delete, :options], expose: ['authorization']
    end
  end \n"
end

def configure_application
  insert_into_file(
    'config/application.rb',
    "require 'sprockets/railtie'\n\n",
    before: 'Bundler.require(*Rails.groups)'
  )
end

def configure_specs
  directory 'spec', force: true
  environment 'config.generators.test_framework = :rspec'
  rails_command 'generate apitome:install'
end

def add_sidekiq
  environment 'config.active_job.queue_adapter = :sidekiq'

  insert_into_file(
    'config/routes.rb',
    "require 'sidekiq/web'\n\n",
    before: 'Rails.application.routes.draw do'
  )

  insert_into_file(
    'config/routes.rb',
    "\n mount Sidekiq::Web => '/sidekiq'\n\n",
    after: 'Rails.application.routes.draw do'
  )
end

def stop_spring
  run 'spring stop'
end

def copy_rubocop
  copy_file '.rubocop.yml'
end

def setup_db
  rails_command 'db:create'
  rails_command 'db:migrate'
end

def copy_docker
  directory 'docker'
  copy_file 'docker-compose.yml'
  copy_file 'docker-compose.development.yml'
end

def copy_env
  copy_file '.env'
  copy_file '.env.development'
end

def copy_docs
  copy_file 'README_EXAMPLE.md', 'README.md'
  copy_file 'CHANGELOG_EXAMPLE.md', 'CHANGELOG.md'
  copy_file 'lemme_check_remote.sh'
  empty_directory 'doc'
end

def configure_xlog
  environment 'config.middleware.use Xlog::Middleware'
end

def setup_abdi
  directory 'infrastructure'
  directory 'data'
  remove_dir 'app/models'
  directory 'business'

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

# Main setup
source_paths

add_gems

after_bundle do
  stop_spring

  copy_templates
  copy_docker
  copy_env
  add_sidekiq
  configure_cors
  configure_application
  configure_specs
  copy_rubocop
  copy_docs
  configure_xlog

  setup_abdi

  setup_db

  git :init
  git add: '.'
  git commit: %q{ -m 'Initial commit' }
end
