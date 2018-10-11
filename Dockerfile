FROM ruby:2.5.1-alpine3.7

COPY . /app

# first, update the packages
RUN apk update && apk upgrade

# this is required so that OpenSSL errors don't appear
RUN apk add ca-certificates && update-ca-certificates && apk add openssl

# add build essentials
RUN apk add build-base

# get Mami requirements
RUN apk add mariadb-dev sqlite-dev postgresql-dev

# move everything
COPY . /app
WORKDIR /app

# install Ruby deps
RUN bundle install

# start
CMD ["ruby", "bot.rb"]
