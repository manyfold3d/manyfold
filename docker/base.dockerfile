## COMMON BASE ##########################################

FROM ruby:3.3.4-alpine AS base
WORKDIR /usr/src/app

RUN apk add --no-cache \
  tzdata

RUN gem install bundler -v 2.4.13
RUN bundle config set --local deployment 'true'
RUN bundle config set --local without 'development test'
