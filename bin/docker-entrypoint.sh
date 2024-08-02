#!/bin/ash
set -e
if [ -f tmp/pids/server.pid ]; then
  rm tmp/pids/server.pid
fi

echo "Preparing database..."
bundle exec rails db:prepare:with_data

echo "Setting database file ownership (SQLite3 only)..."
bundle exec rake db:chown

echo "Cleaning up old cache files..."
bundle exec rake tmp:cache:clear

echo "Setting temporary directory permissions..."
chown -R $PUID:$PGID tmp log

echo "Launching application..."
export RAILS_PORT=$PORT
exec s6-setuidgid $PUID:$PGID $@
