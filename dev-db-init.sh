#!/bin/sh

# Wait for the database to be ready
while ! pg_isready -q -h ${PGHOST:-database} -p ${PGPORT:-5432} -U ${PGUSER:-postgres}
do
  echo "$(date) - waiting for database to start"
  sleep 2
done

# Only run the following commands if MIX_ENV is set to "dev"
if [ "$MIX_ENV" = "dev" ]; then
  echo "Running in development mode: Setting up the database"
  mix ecto.create
  mix ecto.migrate
fi

# Start the Phoenix server
exec "$@"
