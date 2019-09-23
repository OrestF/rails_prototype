def source_paths
  [__dir__]
end

def add_gems
  gem 'sidekiq'
  gem 'r_creds'
  gem 'redis'
  gem 'slim-rails'

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
    gem 'rspec-rails', '~> 4.0.0.beta2'
    gem 'rspec-sidekiq'
    gem 'vcr'
    gem 'fakeredis'
    gem 'factory_bot_rails'
    gem 'faker'
    gem 'database_cleaner'
    gem 'webmock'
    gem 'capybara-webkit'
  end
end

def copy_templates
  # add folders here
end

def configure_specs
  directory 'spec', force: true
  environment 'config.generators.test_framework = :rspec'
end

def add_sidekiq
  environment 'config.active_job.queue_adapter = :sidekiq'

  insert_into_file 'config/routes.rb',
                   "require 'sidekiq/web'\n\n",
                   before: 'Rails.application.routes.draw do'

  insert_into_file 'config/routes.rb',
                   "\n mount Sidekiq::Web => '/sidekiq'\n\n",
                   after: 'Rails.application.routes.draw do'
end

def copy_rubocop
  copy_file '.rubocop.yml'
end

def stop_spring
  run 'spring stop'
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

# Main setup
source_paths

add_gems

after_bundle do
  stop_spring

  copy_templates
  copy_docker
  copy_env
  add_sidekiq
  configure_specs
  copy_rubocop

  setup_db

  git :init
  git add: '.'
  git commit: %q{ -m "Initial commit" }
end
