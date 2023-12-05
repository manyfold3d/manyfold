FROM ruby:3.2-alpine AS build

RUN apk add --no-cache tzdata alpine-sdk postgresql-dev nodejs yarn xz libarchive mesa-gl glfw
RUN gem install foreman

ARG GIT_REF
ARG GIT_SHA

ENV PORT=3214
ENV RACK_ENV=production
ENV RAILS_ENV=production
ENV NODE_ENV=production
ENV RAILS_SERVE_STATIC_FILES=true
ENV GIT_REF=${GIT_REF}
ENV GIT_SHA=${GIT_SHA}

WORKDIR /usr/src/app

COPY package.json .
COPY yarn.lock .
RUN yarn config set network-timeout 600000 -g
RUN yarn install --prod

RUN gem install bundler -v 2.4.13
RUN bundle config set --local deployment 'true'
RUN bundle config set --local without 'development test'
COPY Gemfile* ./
RUN bundle install

COPY . .
RUN \
  DATABASE_URL="nulldb://user:pass@localhost/db" \
  SECRET_KEY_BASE="placeholder" \
  bundle exec rake assets:precompile

EXPOSE 3214
ENTRYPOINT ["bin/docker-entrypoint.sh"]
CMD ["foreman", "start"]
