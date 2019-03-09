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

1.  Copy setup_rails_prototype.sh into folder where you want to create your_rails_app folder
1. Specify rails version and your app name!

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
