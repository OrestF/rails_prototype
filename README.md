# Default rails application v.0.2

Boot up new rails application with configured test environment and all necessary gems.
Default configs are:
* PostgreSQL
* no minitets
* rspec
* pure js - not coffee
* sidekiq as background processing adapter
* redis
* test environment is set
* [XLog](https://github.com/coaxsoft/xlog) - as default errors middleware
* [ABDI](https://gist.github.com/OrestF/084f7cb38c16084234f4c41338c364dc) architecture pre-installed 

### For API version:

* [rspec_api_documentation](https://github.com/zipmark/rspec_api_documentation) - specs and documentation generator
* [blueprinter](https://github.com/procore/blueprinter) - Simple, Fast, and Declarative Serialization Library for Ruby
* [pagy](https://github.com/ddnexus/pagy) - The ultimate pagination ruby gem
* [Oj](https://github.com/ohler55/oj) - Optimized JSON

## Usage
```bash
 $ curl -s -L http://tiny.cc/ueuadz | sh /dev/stdin -r 6.0.0 -t api -n test_app
```
OR
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
