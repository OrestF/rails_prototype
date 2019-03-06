
def source_paths
  [File.expand_path(File.dirname(__FILE__))]
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
    gem 'rspec-rails'
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
  # add folders here
end

def configure_specs
  directory "spec", force: true
  environment "config.generators.test_framework = :rspec"
end

def add_sidekiq
  environment "config.active_job.queue_adapter = :sidekiq"

  insert_into_file "config/routes.rb",
    "require 'sidekiq/web'\n\n",
    before: "Rails.application.routes.draw do"

  insert_into_file "config/routes.rb",
    "\n mount Sidekiq::Web => '/sidekiq'\n\n",
    after: "Rails.application.routes.draw do"
end

def copy_rubocop
  copy_file ".rubocop.yml"
end

def stop_spring
  run "spring stop"
end

def setup_db
  rails_command "db:create"
  rails_command "db:migrate"
end


# Main setup
source_paths

add_gems

after_bundle do
  stop_spring

  copy_templates
  add_sidekiq
  configure_specs
  copy_rubocop

  setup_db

  git :init
  git add: "."
  git commit: %Q{ -m "Initial commit" }
end
