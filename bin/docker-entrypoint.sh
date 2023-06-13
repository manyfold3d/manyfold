#!/bin/sh
set -e

if [ -f tmp/pids/server.pid ]; then
  rm tmp/pids/server.pid
fi

echo "Preparing database..."
bundle exec rails db:prepare

echo "Migrating data..."
bundle exec rails data:migrate

echo "Launching application..."
exec "$@"
