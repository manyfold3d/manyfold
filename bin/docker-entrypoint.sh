#!/bin/sh
set -e

echo "Preparing database..."
bundle exec rails db:prepare

echo "Migrating data..."
bundle exec rails data:migrate

echo "Launching application..."
exec "$@"
