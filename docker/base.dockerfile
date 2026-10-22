## COMMON BASE ##########################################

FROM ruby:3.4.9-alpine3.24 AS base
WORKDIR /usr/src/app

RUN apk add --no-cache \
  tzdata=2026d-r0

RUN gem install bundler -v 2.5.23
RUN bundle config set --local deployment 'true'
RUN bundle config set --local without 'development test'

RUN apk add --no-cache \
  ca-certificates>=20261020-r0 \
  file=5.47-r2 \
  s6-overlay=3.2.3.0-r0 \
  gcompat=1.1.0-r4 \
  jemalloc=5.3.0-r6 \
  imagemagick=7.1.2.34-r0 \
  imagemagick-jpeg=7.1.2.34-r0 \
  imagemagick-webp=7.1.2.34-r0 \
  imagemagick-heic=7.1.2.34-r0 \
  assimp-dev=6.0.4-r0 \
  mesa-egl=26.1.6-r0 \
  vtk=9.5.2-r2 \
  opencascade=7.9.3-r2

RUN apk add --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing draco=1.5.7-r2

# Scripts for cross-platform architecture detection
COPY --from=tonistiigi/xx / /

# Install custom f3d package
RUN wget "https://github.com/manyfold3d/f3d-alpine/releases/download/v4.0.0-r0-1/f3d-4.0.0-r0.`xx-info alpine-arch`.apk" -O /tmp/f3d.apk
RUN apk add --no-cache --allow-untrusted /tmp/f3d.apk
RUN rm /tmp/f3d.apk
