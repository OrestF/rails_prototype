
def source_paths
  [File.expand_path(File.dirname(__FILE__))]
end

def add_gems
  gem 'sidekiq', '~> 5.2', '>= 5.2.5'
  gem 'r_creds', '~> 0.2.0'
  gem 'redis', '~> 4.1'
  gem 'slim-rails', '~> 3.2'

  gem_group :development, :test do
    gem 'dotenv', '~> 2.6'
  end

  gem_group :development do
    gem 'rubocop', '~> 0.65.0'
    gem 'rubycritic', '~> 3.5', '>= 3.5.2'
    gem 'brakeman', '~> 4.4'
    gem 'bullet', '~> 5.9'
  end

  gem_group :test do
    gem 'rspec-rails', '~> 3.8', '>= 3.8.2'
    gem 'rspec-sidekiq', '~> 3.0', '>= 3.0.3'
    gem 'vcr', '~> 4.0'
    gem 'fakeredis', '~> 0.7.0'
    gem 'factory_bot_rails', '~> 5.0', '>= 5.0.1'
    gem 'faker', '~> 1.9', '>= 1.9.3'
    gem 'database_cleaner', '~> 1.7'
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
