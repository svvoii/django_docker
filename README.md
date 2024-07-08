# Django-Docker Setup

This is a simple guide to setting up a Django project with Docker using `venv`, `requirements.txt`, `.env`. As well as `entrypoint.sh` for setting up the docker container.  

The settings will prepare the project to work with a PostgreSQL database as well as having both development `default.py` and `production.py` settings files.  


## 1. Creating a workspace:

**NOTE:** *Skip this step if you already have a Django project or using this repository.*  

```bash
mkdir <project_name>
cd <project_name>
```


## 2. *Creating a virtual environment:*

```bash
python3 -m venv .venv
source .venv/bin/activate
```

## 3. *Installing Django and other packages:*

```bash
pip install --upgrade pip

pip install django
pip install psycopg2-binary

pip freeze > requirements.txt
```

**NOTE 1:** *The `psycopg2-binary` package is not recommended for use in a production environment. It is only for development and testing purposes. We install it here since `psycopg2` cant be installed on school computers.*    

**NOTE 2:** *The `psycopg2` package requires the `libpq-dev` package to be installed on the system (sudo access required) !!! Not the case for school dumps !!!*  

*However, running this in a docker container will not cause any problems. So, just replace `psycopg2-binary` with `psycopg2` in the `requirements.txt` file to have it installed in a docker container. Prior dependencies needed.. (see `entrypoint.sh` bellow for more details)*

## 4. *Modifying the content of `requirements.txt` file (these are necessary dependencies only):*

```txt
Django>=5.0
gunicorn>=22.0
# psycopg2-binary==2.9.9
psycopg2>=2.9
```

*This file will be used to install basic project dependencies in the Docker container.*  

*Packages listed here are the only necessary dependencies (to use `postgresql` as database). You can add more packages as needed.*  


## 5. *Creating new Django project:*

**NOTE:** *Skip this if Django project already exist*

```bash
django-admin startproject my_project
```


## 6. *Split the settings file into development and production settings:*  

*In the `my_project/my_project` directory, create a folder called `settings` and move the `settings.py` file to it, as wella as create another `__init__.py` file in `settings` folder.*

*Adding the following to the `my_project/my_project/settings/__init__.py`:*

```python
import os

def get_secret(secret_id, backup=None):
	return os.getenv(secret_id, backup)

if get_secret('PIPELINE') == 'production':
	from .production import *
else:
    from .default import *

```

*This will allow us to switch between the development and production settings when needed, using `PIPELINE` variable defined in `.env` file*  

*In the `my_project/my_project/settings` directory, rename the `settings.py` file to `default.py`. Then duplicate it. Than rename the copy to `production.py`.*  

**Modify the `production.py` file:**

```python
...
# Adding the get_secret function:
from . import get_secret
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


## 7. *Crafting Dockerfile:*

*Creating `Dockerfile` in the root directory:*  

```Dockerfile
FROM python:3.10-slim-buster

WORKDIR /app

COPY . /app/

RUN chmod +x entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]

EXPOSE ${PORT}
```


## 8. *Creating `.env` file in the root directory (example):*  

```txt
# for Docker container:
PYTHONBUFFERED=1
PORT=8000

# for Django settings:
PIPELINE=production
SECRET_KEY=your_secret_key

# for postgresql:
DB_NAME=postgres
DB_USER=postgres
DB_PASSWORD=postgres
DB_HOST=0.0.0.0
DB_PORT=5432

```


## 9. *Creating `entrypoint.sh` file in the root directory:*  

*This file will be used to install the necessary packages in the Docker container.*

*In the `entrypoint.sh` file, add the following script:*  

```bash
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
```


## 10. *Next running Docker commands to build and run the image:*

```bash
docker build --no-cache -t django-docker:latest .

docker run -p 8000:8000 --env-file .env django-docker:latest
```

*The second command will take a while to run, as it will install the necessary packages in the Docker container.*  


*Once the container is running, the Django project will be accessible at `http://localhost:8000`.*  


**NOTE:** *To push the project as a repository to GitHub, add the following to the `.gitignore` file:*  

*In the root directory, create `.gitignore` file:*

```txt
.venv
.env
```

*For sequrity reasons, the `.env` file should not be pushed to the repository !!!*  
*But you already know that, right?*  


**Project structure:**  

```txt
(root)repository/
|
|── .venv/..
|── my_project/
|	├── my_project/
|	│   ├── settings/
|	│   │   ├── __init__.py
|	│   │   ├── default.py
|	│   │   └── production.py
|	│   ├── __init__.py
|	│   ├── urls.py
|	│   └── wsgi.py
|	├── manage.py
|── .env
|── .gitignore
|── Dockerfile
|── entrypoint.sh
|── requirements.txt
```
