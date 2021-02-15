FROM ruby:3.0.0

ENV PORT 3214
ENV RACK_ENV production
ENV NODE_ENV production
ENV RAILS_SERVE_STATIC_FILES true

RUN curl https://deb.nodesource.com/setup_14.x | bash
RUN curl https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        nodejs yarn build-essential postgresql-client libpq-dev  \
    && rm -rf /var/lib/apt/lists/*

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
