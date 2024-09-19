## BUILD STAGE ##########################################

FROM base AS build

RUN apk add --no-cache \
  alpine-sdk \
  nodejs=~20.15 \
  npm \
  postgresql-dev \
  mariadb-dev \
  libarchive \
  mesa-gl \
  glfw

COPY package.json .
COPY yarn.lock .
RUN npm install --global corepack
RUN corepack enable
RUN yarn config set network-timeout 600000
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
