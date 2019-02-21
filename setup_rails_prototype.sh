# bin/bash

git clone https://github.com/OrestF/rails_prototype.git
rails new $1 -d postgresql -T --skip-coffee -m ./rails_prototype/template.rb
rm -rf ./rails_prototype
echo 'Done!'
