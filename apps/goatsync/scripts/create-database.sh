#!/bin/bash

# GoatSync Database Setup Script
# Run this BEFORE deploying the goatsync container
#
# Usage: ./create-database.sh <password>
# Example: ./create-database.sh $(openssl rand -base64 16)

set -e

DB_USER="goatsync"
DB_NAME="goatsync"
DB_PASSWORD="${1:-}"

if [ -z "$DB_PASSWORD" ]; then
    echo "Usage: $0 <password>"
    echo "Example: $0 \$(openssl rand -base64 16)"
    echo ""
    echo "Or generate and use a random password:"
    echo "  PASSWORD=\$(openssl rand -base64 16)"
    echo "  echo \"Password: \$PASSWORD\""
    echo "  $0 \"\$PASSWORD\""
    exit 1
fi

echo "=== GoatSync Database Setup ==="
echo "Creating database: $DB_NAME"
echo "Creating user: $DB_USER"
echo ""

# Check if postgres-vector is running
if ! podman ps | grep -q postgres-vector; then
    echo "ERROR: postgres-vector container is not running!"
    echo "Start it with: systemctl --user start postgres-vector.service"
    exit 1
fi

# Create database (DDL - cannot be transactional)
echo "Step 1: Creating database..."
podman exec -it postgres-vector psql -U postgresql -d postgres -c "CREATE DATABASE $DB_NAME;" 2>/dev/null || echo "Database may already exist, continuing..."

# Create user and grant permissions (matching db.env pattern from wger)
echo "Step 2: Creating user and granting permissions..."
podman exec -it postgres-vector psql -U postgresql -d postgres -c "
CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
ALTER DATABASE $DB_NAME OWNER TO $DB_USER;
GRANT USAGE ON SCHEMA public TO $DB_USER;
" 2>/dev/null || echo "User may already exist, updating password..."

# If user exists, update password
podman exec -it postgres-vector psql -U postgresql -d postgres -c "ALTER USER $DB_USER WITH PASSWORD '$DB_PASSWORD';" 2>/dev/null || true

echo ""
echo "=== Database Setup Complete ==="
echo ""
echo "IMPORTANT: Update your environment file with this DATABASE_URL:"
echo ""
echo "  DATABASE_URL=postgres://$DB_USER:$DB_PASSWORD@10.0.2.2:5432/$DB_NAME?sslmode=disable"
echo ""
echo "Also generate ENCRYPTION_SECRET:"
echo "  openssl rand -base64 32"
echo ""
echo "Edit: apps/goatsync/environments/local.env"
