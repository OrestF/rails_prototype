# bin/bash

echo 'Loading...'

rvm install $1
rvm use $1
gem install bundler
gem install rails -v $2

git clone https://github.com/OrestF/rails_prototype.git
rails new $3 -d postgresql -T --skip-coffee -m ./rails_prototype/template.rb
rm -rf ./rails_prototype
echo 'Done!'
