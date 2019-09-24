# Default rails application

Boot up new rails application with configured test environment and all necessary gems.
Default configs are:
* PostgreSQL
* no minitets
* rspec
* pure js - not coffee
* sidekiq as background processing adapter
* redis
* test environment is set

## Usage
```bash
 $ curl -s -L https://raw.githubusercontent.com/OrestF/rails_prototype/master/setup.sh | sh /dev/stdin -r 6.0.0 -t api -n test_app
```

### Ruby version must be preinstalled and selected must be preinstalled!
```bash
Options:
    -r         # Rails VERSION
    -t         # Application type: [api classic]
    -n         # Application name

Script options:
    -h         # Show this help message and quit
    -v         # Show script version number and quit"
```

```bash
sh setup_rails_prototype.sh -r 5.2.2 -t api -n my_awesome_app
```