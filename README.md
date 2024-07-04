# Django-Docker Setup

This is a simple guide to setting up a Django project with Docker using `venv`, `requirements.txt`, `.env`. As well as `entrypoint.sh` for setting up the docker container.  

The settings will prepare the project to work with a PostgreSQL database as well as having both development `default.py` and `production.py` settings files.  


## 1. *Creating a virtual environment:*

```bash
python3 -m venv .venv
source .venv/bin/activate

python -V

pip install --upgrade pip

pip install django psycopg2-binary gunicorn

pip freeze > requirements.txt
```

**Note:** *The `psycopg2-binary` package is not recommended for use in a production environment. It is only for development and testing purposes.*  

**Also note:** *The `psycopg2` package requires the `libpq-dev` package to be installed on the system. If it is not installed, the package will not be installed. !!! This is the case for school computers !!!*  

*However, running this in a docker container will not cause any problems. So, just replace `psycopg2-binary` with `psycopg2` in the `requirements.txt` file to run the project in a docker container.*

*The content of `requirements.txt` file:*

```txt
Django>=5.0
gunicorn>=22.0
# psycopg2-binary==2.9.9
psycopg2>=2.9
```


## 2. *Django project:*

**Skip this if Django project already exist**

```bash
django-admin startproject _server .
```

*In the `_server` directory, create a folder called `settings` and move the `settings.py` file to it.*

*In the `_server/settings` directory, create a file called `__init__.py`:*

```python
import os

def get_secret(secret_id, backup=None):
	return os.getenv(secret_id, backup)

if get_secret('PIPELINE') == 'production':
	from .production import *
else:
    from .default import *

```

*This will distinguish between the development and production settings.*  

*In the `_server/settings` directory, rename the `settings.py` file to `default.py`. Then duplicate it and rename the copy to `production.py`.*  

**Modify the `production.py` file:**

```python
...
# Adding the get_secret function:
from _server.settings import get_secret
...
# Modify the settings:

SECRET_KEY = get_secret('SECRET_KEY')

DEBUG = False

ALLOWED_HOSTS = ['*']
...
...
# Changing database settings:
DATABASES = {
	'default': {
		'ENGINE': 'django.db.backends.postgresql',
		'NAME': get_secret('DB_NAME'),
		'USER': get_secret('DB_USER'),
		'PASSWORD': get_secret('DB_PASSWORD'),
		'HOST': get_secret('DB_HOST'),
		'PORT': get_secret('DB_PORT'),
	}
}
...
```


## 3. *Crafting Dockerfile:*

*Creating `Dockerfile` in the root directory:*  

```Dockerfile
FROM python:3.10-slim-buster

WORKDIR /app

COPY . /app/

RUN chmod +x entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]

EXPOSE ${PORT}
```


## 4. *Creating `.env` file in the root directory (example):*  

```txt
# This file contains all the environment variables that are used in the project

PYTHONBUFFERED=1
PORT=8000

# Django variables
PIPELINE=production
SECRET_KEY=your_secret_key

# postgresql variables
DB_NAME=postgres
DB_USER=postgres
DB_PASSWORD=postgres
DB_HOST=0.0.0.0
DB_PORT=5432

```


## 5. *Creating `entrypoint.sh` file in the root directory:*  

```bash
#!/bin/bash

# Exit on error
set -e

# Start Gunicorn with the bind option using the PORT environment variable
exec gunicorn _server.wsgi:application --bind 0.0.0.0:${PORT}
```


## 6. *Next running Docker commands to build and run the image:*

```bash
docker build -t django-docker:latest .

docker run -p 8000:8000 --env-file .env django-docker:latest
```


*Once the container is running, the Django project will be accessible at `http://localhost:8000`.*  


**NOTE:** *To push the project as a repository to GitHub, add the following to the `.gitignore` file:*  

```txt
# .gitignore
.venv
.env
```

*For sequrity reasons, the `.env` file should not be pushed to the repository !!!*  
*But you already know that, right?*  

