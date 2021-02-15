#!/bin/bash
set -e

echo "Preparing database..."
bundle exec rails db:prepare

echo "Launching application..."
exec "$@"
