#!/bin/sh

# Wait for the database to be ready
while ! pg_isready -q -h ${PGHOST:-database} -p ${PGPORT:-5432} -U ${PGUSER:-postgres}
do
  echo "$(date) - waiting for database to start"
  sleep 2
done

# Check if the database exists
DB_EXISTS=$(PGPASSWORD=$PGPASSWORD psql -U $PGUSER -h $PGHOST -p $PGPORT -d $PGDATABASE -c '\dt' > /dev/null 2>&1; echo $?)

if [ $DB_EXISTS -ne 0 ]; then
  echo "Database does not exist. Running mix ecto.create and mix ecto.migrate..."
  mix ecto.create && mix ecto.migrate
else
  echo "Database already exists. Skipping mix ecto.create and mix ecto.migrate."
fi

# Optionally run the server or other commands
exec "$@"
