#!/bin/bash

echo "Running wger first-time setup..."

# Wait for database to be ready
echo "Waiting for database to be ready..."
sleep 10

# Run Django migrations
echo "Running database migrations..."
podman exec wger-web python3 manage.py migrate

# Load all necessary fixtures (languages, muscles, equipment, etc.)
echo "Loading application fixtures..."
podman exec wger-web wger load-fixtures

# Collect static files
echo "Collecting static files..."
podman exec wger-web python3 manage.py collectstatic --noinput

# Create superuser
echo "Creating admin user..."
echo "Username: admin"
echo "Email: admin@wger.local"
echo "Password: adminadmin"
podman exec wger-web python3 manage.py shell -c "
from django.contrib.auth.models import User
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@wger.local', 'adminadmin')
    print('Admin user created')
else:
    print('Admin user already exists')
"

echo ""
echo "wger setup complete!"
echo "Access wger at: http://wger-web.aevion.lan"
echo "Admin login: admin / adminadmin"
echo ""
echo "To load additional exercise and nutrition data (optional, recommended):"
echo "  podman exec wger-web python3 manage.py sync-exercises"
echo "  podman exec wger-web python3 manage.py download-exercise-images"
echo "  podman exec wger-web python3 manage.py download-exercise-videos"
echo "  podman exec wger-web python3 manage.py sync-ingredients"
echo ""
echo "Note: Syncing ingredients uses ~1GB disk space and may take several hours"
