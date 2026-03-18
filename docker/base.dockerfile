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
  assimp-dev \
  mesa-egl

# Install latest VTK from Alpine edge
RUN apk add --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community \
  vtk

# Scripts for cross-platform architecture detection
COPY --from=tonistiigi/xx / /

# Install custom f3d package
RUN wget "https://github.com/manyfold3d/f3d-alpine/releases/download/v3.4.1-r2/f3d-3.4.1-r2.`xx-info alpine-arch`.apk" -O /tmp/f3d.apk
RUN apk add --no-cache --allow-untrusted /tmp/f3d.apk
RUN rm /tmp/f3d.apk
