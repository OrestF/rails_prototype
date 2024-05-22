FROM --platform=linux/amd64 ruby:3.2.3

# Set an environment variable where the Rails app is installed to inside of Docker image
ENV RAILS_ROOT /var/www/$APP_NAME

# Add label for watchtower
LABEL com.centurylinklabs.watchtower.enable="true"

# make a new directory where our project will be copied
RUN mkdir -p $RAILS_ROOT

# Set working directory within container
WORKDIR $RAILS_ROOT

# Setting env up
ENV RAILS_ENV=$RAILS_ENV
ENV RAKE_ENV=$RAILS_ENV
ENV RACK_ENV=$RAILS_ENV

# Installing dependencies

# install Openssl 1.1.1w needed for wkhtmltopdf
#RUN wget http://ftp.uk.debian.org/debian/pool/main/o/openssl/libssl1.1_1.1.1w-0+deb11u1_amd64.deb -P /tmp \
#    && dpkg -i /tmp/libssl1.1_1.1.1w-0+deb11u1_amd64.deb

# Adding gems
COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock
# development/production differs in bundle install
RUN gem install bundler
RUN bundle install --jobs 20 --retry 5

# Adding project files
COPY . .

# CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
RUN ["chmod", "+x", "./docker-entrypoint.sh"]
RUN ["chmod", "+x", "./docker-entrypoint.test.sh"]
RUN ["chmod", "+x", "./docker-entrypoint-sidekiq.sh"]
RUN ["chmod", "+x", "./docker-entrypoint-anycable.sh"]

ENTRYPOINT ["sh", "./docker-entrypoint.sh"]
