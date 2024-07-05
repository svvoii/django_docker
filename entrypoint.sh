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

# Start Gunicorn with the bind option using the PORT environment variable
cd my_project
exec gunicorn my_project.wsgi:application --bind 0.0.0.0:${PORT}
