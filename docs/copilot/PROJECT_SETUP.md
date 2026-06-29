# PROJECT SETUP

## Project name

akkezxla-ligue-1

---

# Goal

Build a modern Laravel 13 REST API entirely running inside Docker.

The repository must be clonable and executable without installing PHP, Composer or PostgreSQL on the host machine.

The only required software is:

- Docker
- Docker Compose

A fresh clone followed by:

```bash
docker compose up --build
```

must automatically generate a complete Laravel application.

---

# Repository structure

```
.github/

backend/
    (Laravel application)

infra/
    docker/
        dev/
            Dockerfile
            docker-compose.yml
            nginx.conf
            entrypoint.sh

        prod/
            Dockerfile
            docker-compose.yml
            nginx.conf
            entrypoint.sh

docs/
    copilot/
        PROJECT_SETUP.md
        CODING_RULES.md

README.md
```

The Laravel application lives directly inside the **backend/** directory.

There must never be a backend/laravel directory.

---

# Technology stack

Laravel 13

PHP 8.4

PostgreSQL 17

Nginx

Composer

Docker

Docker Compose

Adminer (development only)

Github Actions

Render

---

# Development environment

Create four services.

## app

PHP-FPM container.

Responsibilities:

- create Laravel if backend is empty
- install Composer dependencies
- execute artisan commands
- run php-fpm

Working directory:

```
/var/www
```

Mount:

```
backend -> /var/www
```

---

## nginx

Reverse proxy.

Expose:

```
80
```

Root directory:

```
/var/www/public
```

---

## postgres

Version:

17

Database:

```
ligue1
```

User:

```
laravel
```

Password:

```
laravel
```

Persistent volume required.

---

## adminer

Development only.

Expose:

```
8080
```

---

# Docker network

Create a dedicated bridge network.

Name:

```
ligue1
```

Every service must use it.

---

# Docker volumes

Persistent volume:

```
postgres_data
```

Laravel source code is **not** stored inside Docker volumes.

Only PostgreSQL data is persisted.

---

# Development Dockerfile

Use an official PHP FPM image.

Install:

- git
- unzip
- curl
- zip

PHP extensions:

- pdo_pgsql
- mbstring
- bcmath
- intl
- gd
- exif
- pcntl
- opcache
- zip

Install Composer.

Copy an entrypoint.

The container must start using this entrypoint.

---

# Entrypoint responsibilities

At startup:

## 1.

If backend is empty

Execute:

```bash
composer create-project laravel/laravel .
```

---

## 2.

If backend already contains Laravel

Execute:

```bash
composer install
```

---

## 3.

If .env does not exist

Copy:

```
.env.example
```

Automatically configure:

```
APP_ENV=local
APP_DEBUG=true
APP_URL=http://localhost

DB_CONNECTION=pgsql
DB_HOST=postgres
DB_PORT=5432
DB_DATABASE=ligue1
DB_USERNAME=laravel
DB_PASSWORD=laravel
```

---

## 4.

Generate

```bash
php artisan key:generate
```

only if APP_KEY is empty.

---

## 5.

Wait until PostgreSQL is available.

---

## 6.

Run

```bash
php artisan migrate --force
```

---

## 7.

Start

```
php-fpm
```

---

# Production

Do not install dev dependencies.

Composer:

```
composer install --no-dev --optimize-autoloader
```

Cache:

```
php artisan config:cache

php artisan route:cache

php artisan event:cache

php artisan view:cache
```

No Adminer.

No bind mounts.

The Laravel application must be copied inside the image.

---

# Github Actions

Create a CI pipeline.

Trigger:

- push
- pull_request

Workflow:

Checkout

Install PHP

Install Composer dependencies

Copy .env

Generate APP_KEY

Start PostgreSQL

Wait for database

Run migrations

Execute:

Laravel Pint

PHPStan

PHPUnit

The workflow must fail immediately if one step fails.

---

# Render deployment

The application will be deployed on Render.

Support environment variables.

Never hardcode production values.

Support:

APP_KEY

APP_ENV

APP_DEBUG

DATABASE_URL

Use the PostgreSQL instance provided by Render.

---

# General constraints

Prefer:

- official Docker images
- multi-stage builds
- cache optimization
- reproducible builds
- lightweight images

Never duplicate configuration.

Every configurable value must be overridable through environment variables.

---

# Expected result

A developer clones the repository.

Runs:

```bash
docker compose up --build
```

Then immediately has:

- Laravel installed
- PostgreSQL running
- migrations executed
- Adminer available
- API available at http://localhost