# Dream project [example readme]

## Project scope

Ultimate solution for tours/hotels management.  

- Create, edit, import products
- Order product
- SafeCharge payment system
- Configurable reporting and analytics
- Suppliers CRM

## Runtime environment

The infrasturcture of Dream project consists of the following services:

- Dream project application
- PostgreSQL database
- Redis in-memory database
- Sidekiq background processing
- AWS S3 for assets
- Logentries for logging
- SafeCharge for payments 
- Mailjet for mails

< Architecture overview C4 model here - provided soon >

## Commands

The list of custom tasks/commands/scripts that could be run within application 

```ruby
rake app:warmup_orders_cache
rake app:warmup_products_cache
rake app:warmup_cache
```

## Development environment

Steps to run application locally.  
Script that automates development setup would be a huge plus!

#### Automated setup

```
# rails app

$ bin/setup
Check PostgreSQL - done 
Check Redis - done 
Check Sidekiq - done 

Application is ready!
```

#### Manual setup

1. Install ruby/python/js whatever
1. Install PostgreSQL
1. Install Redis
1. Install something specific for your project

#### Automated boot

```
# just an example

$ bin/local-up
Starting PostgreSQL...
Starting Redis...
Starting Dream app..

Application is up and running!

```

#### Manual boot

1. Run PostgreSQL in background
1. `$ redis-server`
1. `$ rails s`


## Test environment

How to run tests, linters, etc.

- Linter `$ rubocop`
- Test suit `$ rspec`