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
  nodejs=~22.11 \
  npm \
  postgresql-dev \
  mariadb-dev \
  libarchive

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
  bundle exec rake assets:precompile
