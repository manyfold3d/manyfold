#!/usr/bin/env bash
set -Eeo pipefail
# TODO add "-u"
echo "entrypoint start"

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
		exit 1
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi
	export "$var"="$val"
	unset "$fileVar"
}

isLikelyManyfold=
case "$1" in
	rails | rake | foreman ) isLikelyManyfold=1 ;;
esac

_fix_permissions() {
	# https://www.redmine.org/projects/redmine/wiki/RedmineInstall#Step-8-File-system-permissions
	local dirs=( config log tmp ) args=()
	if [ "$(id -u)" = '0' ]; then
		args+=( '(' '!' -user manyfold -exec chown manyfold:manyfold '{}' + ')' )
	fi
	# directories 755, files 644:
	args+=( '(' -type d '!' -perm 755 -exec sh -c 'chmod 755 "$@" 2>/dev/null || :' -- '{}' + ')' )
	args+=( '(' -type f '!' -perm 644 -exec sh -c 'chmod 644 "$@" 2>/dev/null || :' -- '{}' + ')' )
	if [ ${#args[@]} -gt 0 ]; then
		find "${dirs[@]}" "${args[@]}"
	fi
}


# allow the container to be started with `--user`
if [ -n "$isLikelyManyfold" ] && [ "$(id -u)" = '0' ]; then
	_fix_permissions
	exec su-exec manyfold "$BASH_SOURCE" "$@"
fi

if [ -n "$isLikelyManyfold" ]; then
	_fix_permissions
	if [ ! -f './config/database.yml' ]; then
		file_env 'MANYFOLD_DB_POSTGRES'
		if [ "$POSTGRES_PORT_5432_TCP" ] && [ -z "$MANYFOLD_DB_POSTGRES" ]; then
			export MANYFOLD_DB_POSTGRES='postgres'
			echo "setting postgres"
		fi

		if [ "$MANYFOLD_DB_POSTGRES" ]; then
			adapter='postgresql'
			host="$MANYFOLD_DB_POSTGRES"
			file_env 'MANYFOLD_DB_PORT' '5432'
			file_env 'MANYFOLD_DB_USERNAME' "${POSTGRES_ENV_POSTGRES_USER:-postgres}"
			file_env 'MANYFOLD_DB_PASSWORD' "${POSTGRES_ENV_POSTGRES_PASSWORD}"
			file_env 'MANYFOLD_DB_DATABASE' "${POSTGRES_ENV_POSTGRES_DB:-${MANYFOLD_DB_USERNAME:-}}"
			file_env 'MANYFOLD_DB_ENCODING' 'utf8'
		else
			echo >&2
			echo >&2 'warning: missing MANYFOLD_DB_POSTGRES environment variables'
			echo >&2
			echo >&2 '*** Using sqlite3 as fallback. ***'
			echo >&2

			adapter='sqlite3'
			host='localhost'
			file_env 'MANYFOLD_DB_PORT' ''
			file_env 'MANYFOLD_DB_USERNAME' 'manyfold'
			file_env 'MANYFOLD_DB_PASSWORD' ''
			file_env 'MANYFOLD_DB_DATABASE' 'sqlite/manyfold.db'
			file_env 'MANYFOLD_DB_ENCODING' 'utf8'

			mkdir -p "$(dirname "$MANYFOLD_DB_DATABASE")"
			if [ "$(id -u)" = '0' ]; then
				find "$(dirname "$MANYFOLD_DB_DATABASE")" \! -user manyfold -exec chown manyfold '{}' +
			fi
		fi

		MANYFOLD_DB_ADAPTER="$adapter"
		MANYFOLD_DB_HOST="$host"
		echo "$RAILS_ENV:" > config/database.yml
		cat config/database.yml
		for var in \
			adapter \
			host \
			port \
			username \
			password \
			database \
			encoding \
		; do
			env="MANYFOLD_DB_${var^^}"
			val="${!env}"
			[ -n "$val" ] || continue
			echo "  $var: \"$val\"" >> config/database.yml
		done
	fi

	# install additional gems for Gemfile.local and plugins
	bundle check || bundle install

	if [ ! -s config/secrets.yml ]; then
		file_env 'MANYFOLD_SECRET_KEY_BASE'
		if [ -n "$MANYFOLD_SECRET_KEY_BASE" ]; then
			cat > 'config/secrets.yml' <<-YML
				$RAILS_ENV:
				  secret_key_base: "$MANYFOLD_SECRET_KEY_BASE"
			YML
		elif [ ! -f config/initializers/secret_token.rb ]; then
			bundle exec rake generate_secret_token
		fi
	fi
	if [ "$1" != 'rake' -a -z "$MANYFOLD_NO_DB_MIGRATE" ]; then
		bundle exec rake db:migrate
	fi

	if [ "$1" != 'rake' -a -n "$MANYFOLD_PLUGINS_MIGRATE" ]; then
		bundle exec rake manyfold:plugins:migrate
	fi

	bundle exec rake assets:precompile

	# remove PID file to enable restarting the container
	rm -f tmp/pids/server.pid
fi
echo "entrypoint end"
exec "$@"