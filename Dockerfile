FROM ruby:3.0-alpine
RUN apk add tzdata alpine-sdk postgresql-dev nodejs yarn

ENV PORT 3214
ENV RACK_ENV production
ENV NODE_ENV production
ENV RAILS_SERVE_STATIC_FILES true


RUN gem install bundler -v 2.2.4

WORKDIR /usr/src/app
COPY . .
RUN bundle config set --local deployment 'true'
RUN bundle config set --local without 'development test'
RUN bundle install
RUN yarn install --prod

RUN \
  SECRET_KEY_BASE="placeholder" \
  bundle exec rake assets:precompile

EXPOSE 3214
ENTRYPOINT ["bin/docker-entrypoint.sh"]
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
