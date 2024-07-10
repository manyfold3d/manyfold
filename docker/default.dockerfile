## COMMON BASE ##########################################

FROM ruby:3.3.1-alpine3.18 AS base
WORKDIR /usr/src/app

RUN apk add --no-cache \
  tzdata

RUN gem install bundler -v 2.4.13
RUN bundle config set --local deployment 'true'
RUN bundle config set --local without 'development test'

## BUILD STAGE ##########################################

FROM base AS build

RUN apk add --no-cache \
  alpine-sdk \
  nodejs \
  postgresql-dev \
  mariadb-dev \
  libarchive \
  mesa-gl \
  glfw \
  yarn

COPY package.json .
COPY yarn.lock .
RUN yarn config set network-timeout 600000 -g
RUN yarn install

COPY .ruby-version .
COPY Gemfile* ./
RUN bundle install

COPY . .
RUN \
  DATABASE_URL="nulldb://user:pass@localhost/db" \
  SECRET_KEY_BASE="placeholder" \
  RACK_ENV="production" \
  bundle exec rake assets:precompile

## RUNTIME STAGE ##########################################

FROM base as runtime

RUN apk add --no-cache \
  file \
  s6-overlay

COPY . .
COPY --from=build /usr/src/app/vendor/bundle vendor/bundle
COPY --from=build /usr/src/app/public/assets public/assets

# Copy only the dynamic libraries we need from the build image
# It would be better to statically link the gems during build, if we can
COPY --from=build \
  /usr/lib/libmariadb.so.* \
  /usr/lib/libarchive.so.* \
  /lib/libacl.so.*\
  /usr/lib/libexpat.so.* \
  /usr/lib/liblzma.so.* \
  /usr/lib/libzstd.so.* \
  /usr/lib/liblz4.so.* \
  /usr/lib/libbz2.so.* \
  /usr/lib/libpq.so.* \
  /usr/lib/libGL.so.* \
  /usr/lib/libglapi.so.* \
  /usr/lib/libdrm.so.* \
  /usr/lib/libX11.so.* \
  /usr/lib/libxcb-glx.so.* \
  /usr/lib/libxcb.so.* \
  /usr/lib/libX11-xcb.so.* \
  /usr/lib/libxcb-dri2.so.* \
  /usr/lib/libXext.so.* \
  /usr/lib/libXfixes.so.* \
  /usr/lib/libXxf86vm.so.* \
  /usr/lib/libxcb-shm.so.* \
  /usr/lib/libxshmfence.so.* \
  /usr/lib/libxcb-dri3.so.* \
  /usr/lib/libxcb-present.so.* \
  /usr/lib/libxcb-sync.so.* \
  /usr/lib/libxcb-xfixes.so.* \
  /usr/lib/libxcb-randr.so.* \
  /usr/lib/libXau.so.* \
  /usr/lib/libXdmcp.so.* \
  /usr/lib/libbsd.so.* \
  /usr/lib/libmd.so.* \
  /usr/lib/libglfw.so.* \
  /usr/lib

ARG APP_VERSION
ARG GIT_SHA
ENV APP_VERSION=$APP_VERSION
ENV GIT_SHA=$GIT_SHA

# Runtime environment variables
ENV PORT=3214
ENV RACK_ENV=production
ENV RAILS_ENV=production
ENV NODE_ENV=production
ENV RAILS_SERVE_STATIC_FILES=true
# PUID and PGID env vars - these control what user the app is run as inside
# the entrypoint script. Default to root for backwards compatibility with existing
# installations, but the admin will be warned if these aren't overridden with something
# else at runtime, and this default will be removed in future.
ENV PUID=0
ENV PGID=0

RUN gem install foreman

EXPOSE 3214
ENTRYPOINT ["bin/docker-entrypoint.sh"]
CMD ["foreman", "start"]
