#!/bin/bash

# Source:
#   https://github.com/mrts/docker-postgresql-multiple-databases
#   https://github.com/MartinKaburu/docker-postgresql-multiple-databases

set -e
set -u

mkdir -p /var/lib/postgresql/data

function create_user_and_database() {
    local database=$1
    local user=$2
    local password=$3

    echo "  Creating Database ='$database', User = '$user' with Password = '$password'"
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
        CREATE USER "$user" WITH PASSWORD '$password';
        CREATE DATABASE $database;
        GRANT ALL PRIVILEGES ON DATABASE $database TO $user;
        ALTER DATABASE $database OWNER TO $user;
        GRANT USAGE ON SCHEMA public TO $user;
EOSQL
}

# GRANT ALL ON SCHEMA public TO $user;
# GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $user;
# GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $user;
# GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO $user;
# GRANT CREATE ON SCHEMA public TO $user;

if [ -n "$POSTGRES_MULTIPLE_DATABASES" ]; then
	echo "Multiple database creation requested: $POSTGRES_MULTIPLE_DATABASES"
	for db in $(echo $POSTGRES_MULTIPLE_DATABASES | tr ':' ' '); do
        create_user_and_database $(echo "$db" | tr ',' ' ')
	done
	echo "Multiple databases created"
fi


echo "----------XXX NOTE: RuN This Manually XXX----------"
sleep 10

echo "Enabling Vector Extension for User 'immich'"
# CREATE EXTENSION IF NOT EXISTS vectors;
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    ALTER ROLE immich WITH SUPERUSER;
    SET ROLE immich;
    CREATE EXTENSION vectors;
    RESET ROLE;
    ALTER ROLE immich WITH NOSUPERUSER;
EOSQL
