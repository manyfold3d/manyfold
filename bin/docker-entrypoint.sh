#!/bin/ash
set -e
if [ -f tmp/pids/server.pid ]; then
  rm tmp/pids/server.pid
fi

echo "Preparing database..."
bundle exec rails db:prepare:with_data

echo "Cleaning up old cache files..."
bundle exec rake tmp:cache:clear

echo "Setting temporary directory permissions..."
chown -R $PUID:$PGID tmp log

echo "Launching application..."
exec s6-setuidgid $PUID:$PGID $@
