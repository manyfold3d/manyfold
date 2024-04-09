#!/bin/ash
set -e
if [ -f tmp/pids/server.pid ]; then
  rm tmp/pids/server.pid
fi

# List of required variables to be set for modular database string generation
MODULAR_STRING_COMPONENTS="DATABASE_HOST DATABASE_USER DATABASE_PASSWORD DATABASE_NAME"

# Check if the required vars are set, if they are, generate the URL string, else exit with error code 1
echo "Executing database url substitution hack"
env
if [ -z ${DATABASE_URL} ]; then
	echo "DATABASE_URL appears to be empty, proceeding with modular string generation"
	for VAR in ${MODULAR_STRING_COMPONENTS}; do
		if [ -z "${VAR}" ]; then
			echo "${VAR} = ${!VAR}"
			echo "${VAR} is unset" && exit 1
		fi
	done
	echo "Required variables check passed"
	DATABASE_URL="postgresql://${DATABASE_USER}:${DATABASE_PASSWORD}@${DATABASE_HOST}/${DATABASE_NAME}?pool=5"
fi

echo "Preparing database..."
bundle exec rails db:prepare:with_data

echo "Clearing up old jobs..."
bundle exec rake jobs:clear

echo "Launching application..."
exec "$@"
