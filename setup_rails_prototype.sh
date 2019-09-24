current_version="0.0.1beta#2a345"
usage="Usage:
$(basename "$0") [options]

Options:
    -r         # Rails VERSION
    -t         # Application type: [api classic]
    -n         # Application name

Script options:
    -h         # Show this help message and quit
    -v         # Show script version number and quit"

while getopts r:t:n::hv option; do
  case "${option}" in
    r) VERSION=${OPTARG};;
    t) TYPE=${OPTARG};;
    n) APP_NAME=${OPTARG};;
    h) echo "$usage"
       exit 0
       ;;
    v) echo "$(basename "$0") $current_version"
       exit 0
       ;;
  esac
done

echo 'Loading...'

gem install bundler
gem install rails -v $VERSION

if [ x$TYPE = x"api" ]
then
    echo 'Rails API setup started'
    git clone -b rails_api --single-branch https://github.com/OrestF/rails_prototype.git
    rails _$VERSION\_ new $APP_NAME --api -d postgresql -T --skip-coffee -m ./rails_prototype/template.rb
    rm -rf ./rails_prototype
else
    echo 'Rails setup started'
    git clone -b rails_monolith --single-branch https://github.com/OrestF/rails_prototype.git
    rails _$VERSION\_ new $APP_NAME -d postgresql -T --skip-coffee -m ./rails_prototype/template.rb
    rm -rf ./rails_prototype
fi
echo 'Done!'
