#!/bin/sh
set -e
if [ -f tmp/pids/server.pid ]; then
  rm tmp/pids/server.pid
fi

echo "Preparing database..."
bundle exec rails db:prepare:with_data

echo "Launching application..."
exec "$@"
