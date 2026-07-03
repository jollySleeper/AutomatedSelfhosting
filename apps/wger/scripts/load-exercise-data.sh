#!/bin/bash
# Script to load additional wger exercise and nutrition data
# This should be run after the initial setup (first-run.sh) is complete

set -e  # Exit on error

echo "=========================================="
echo "Loading Additional wger Exercise Data"
echo "=========================================="
echo ""

echo "1. Syncing exercises from wger.de..."
echo "   This will download the latest exercise database"
podman exec wger-web python3 manage.py sync-exercises
echo "   ✓ Exercises synced"
echo ""

echo "2. Downloading exercise images..."
echo "   This will download images for all exercises"
podman exec wger-web python3 manage.py download-exercise-images
echo "   ✓ Exercise images downloaded"
echo ""

echo "3. Downloading exercise videos..."
echo "   This will download video demonstrations"
podman exec wger-web python3 manage.py download-exercise-videos
echo "   ✓ Exercise videos downloaded"
echo ""

echo "=========================================="
echo "Exercise data loaded successfully!"
echo "=========================================="
echo ""
echo "Optional: Load nutrition/ingredient data"
echo "Warning: This requires ~1GB disk space and may take several hours"
echo ""
echo "To load nutrition data, run:"
echo "  podman exec wger-web python3 manage.py sync-ingredients"
echo ""
echo "To warm up the exercise API cache (improves performance):"
echo "  podman exec wger-web python3 manage.py warmup-exercise-api-cache"
