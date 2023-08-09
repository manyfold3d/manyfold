#!/bin/sh
set -e
if [ -f tmp/pids/server.pid ]; then
  rm tmp/pids/server.pid
fi

echo "Preparing database..."
bundle exec rails db:prepare:with_data

echo "Clearing up old jobs..."
bundle exec rake jobs:clear

echo "Launching application..."
exec "$@"
