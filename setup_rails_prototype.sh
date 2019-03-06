#!/usr/bin/env bash
# bin/bash

echo 'Loading...'

gem install bundler
gem install rails -v $2

if [ $1 == "api" ]
then
    echo 'Rails API setup started'
    git clone https://github.com/OrestF/rails_api_prototype.git
    rails new $3 --api -d postgresql -T --skip-coffee -m ./rails_api_prototype/template.rb
    rm -rf ./rails_api_prototype
else
    echo 'Rails setup started'
    git clone https://github.com/OrestF/rails_prototype.git
    rails new $3 -d postgresql -T --skip-coffee -m ./rails_prototype/template.rb
    rm -rf ./rails_prototype
fi
echo 'Done!'
