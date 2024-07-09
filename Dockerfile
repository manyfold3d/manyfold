ARG BASE=ruby:3.3.1-alpine3.18
ARG WORKDIR=/usr/src/app

# Build-time constants
ARG APP_VERSION
ARG GIT_SHA

## BUILD STAGE ##########################################

FROM ${BASE} AS build

RUN apk add --no-cache \
  tzdata \
  alpine-sdk \
  postgresql-dev \
  mariadb-dev \
  nodejs \
  yarn \
  xz \
  libarchive \
  mesa-gl \
  glfw

WORKDIR /usr/src/app

COPY package.json .
COPY yarn.lock .
RUN yarn config set network-timeout 600000 -g
RUN yarn install

RUN gem install bundler -v 2.4.13
RUN bundle config set --local deployment 'true'
RUN bundle config set --local without 'development test'
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

FROM $BASE
WORKDIR /usr/src/app

RUN apk add --no-cache \
  s6-overlay


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
