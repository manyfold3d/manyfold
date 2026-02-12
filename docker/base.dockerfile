## COMMON BASE ##########################################

FROM ruby:3.4.8-alpine3.23 AS base
WORKDIR /usr/src/app

RUN apk add --no-cache \
  tzdata

RUN gem install bundler -v 2.5.23
RUN bundle config set --local deployment 'true'
RUN bundle config set --local without 'development test'

RUN apk add --no-cache \
  file \
  s6-overlay \
  gcompat \
  jemalloc \
  imagemagick \
  imagemagick-jpeg \
  imagemagick-webp \
  imagemagick-heic \
  assimp-dev
