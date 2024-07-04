#!/bin/bash

# Exit on error
set -e

# Install psycopg2 dependencies (to use PostgreSQL with Django)
apt-get update && apt-get install -y \
	build-essential \
	libpq-dev \
	&& rm -rf /var/lib/apt/lists/* # this will clean up the apt-get cache

# Upgrade pip
pip install --upgrade pip

# Install dependencies
pip install -r requirements.txt

# DEBUG:
echo "Current directory: $(pwd)"
echo "Files in current directory:"
ls -la

echo "Files in my_project:"
ls -la my_project/

# Start Gunicorn with the bind option using the PORT environment variable
exec gunicorn my_project.my_project.wsgi:application --bind 0.0.0.0:${PORT}
