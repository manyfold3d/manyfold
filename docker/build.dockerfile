## BUILD STAGE ##########################################

FROM base AS build

RUN apk add --no-cache \
  alpine-sdk \
  bzip2 \
  ca-certificates \
  gmp-dev \
  libffi-dev \
  procps \
  yaml-dev \
  zlib-dev \
  nodejs=~22.15.1 \
  npm \
  postgresql-dev \
  mariadb-dev \
  libarchive \
  imagemagick

COPY package.json .
COPY yarn.lock .
RUN npm install --global corepack
RUN corepack enable yarn
RUN yarn install

COPY .ruby-version .
COPY Gemfile* ./
RUN bundle install

COPY . .
RUN \
  DATABASE_URL="nulldb://user:pass@localhost/db" \
  SECRET_KEY_BASE="placeholder" \
  RACK_ENV="production" \
  RAILS_ASSETS_PRECOMPILE=1 \
  bundle exec rake assets:precompile
