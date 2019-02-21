# bin/bash

echo 'Loading...'

gem install bundler
gem install rails -v $1

git clone https://github.com/OrestF/rails_prototype.git
rails new $2 -d postgresql -T --skip-coffee -m ./rails_prototype/template.rb
rm -rf ./rails_prototype
echo 'Done!'
