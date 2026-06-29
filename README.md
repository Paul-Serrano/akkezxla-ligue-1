# akkezxla-ligue-1

Docker-first Laravel 13 REST API stack with PHP 8.4, PostgreSQL 17, Nginx, and GitHub Actions.

The project is designed so you can run it without installing PHP, Composer, or PostgreSQL on your host machine.

## Prerequisites

- Docker
- Docker Compose

## Repository Structure

- backend: Laravel application source code
- infra/docker/dev: Development Docker stack
- infra/docker/prod: Production Docker stack
- .github/workflows: CI pipeline
- docs/copilot: Project requirements and coding rules

## Install

1. Clone the repository.
2. Move to the repository root.

    git clone <your-repository-url>
    cd akkezxla-ligue-1

No additional local installation is required.

## Start the Project (Development)

Run from the repository root:

    docker compose -f infra/docker/dev/docker-compose.yml up --build

What happens automatically on first startup:

- Laravel is created in backend if empty
- Composer dependencies are installed
- .env is created from .env.example
- APP and DB environment values are configured
- APP_KEY is generated if missing
- The app waits for PostgreSQL
- Migrations are executed
- PHP-FPM starts
- Nginx serves the API
- Adminer is exposed for database inspection

Development endpoints:

- API: http://localhost
- Adminer: http://localhost:8080
- PostgreSQL host inside Docker network: postgres

Adminer login values:

- System: PostgreSQL
- Server: postgres
- Username: laravel
- Password: laravel
- Database: ligue1

## Stop the Project

Run from the repository root:

    docker compose -f infra/docker/dev/docker-compose.yml down

This keeps PostgreSQL data in the persistent volume.

## Stop and Remove Database Volume

Run this only if you want a full database reset:

    docker compose -f infra/docker/dev/docker-compose.yml down -v

## Common Development Commands

Run artisan commands in the app container:

    docker compose -f infra/docker/dev/docker-compose.yml exec app php artisan list

Run tests:

    docker compose -f infra/docker/dev/docker-compose.yml exec app php artisan test

Run migrations manually:

    docker compose -f infra/docker/dev/docker-compose.yml exec app php artisan migrate --force

## Start the Project (Production Stack Locally)

Run from the repository root:

    docker compose -f infra/docker/prod/docker-compose.yml up --build

Production stack characteristics:

- No Adminer service
- No bind mounts
- Laravel application is copied into images
- Composer installs without dev dependencies
- Laravel caches are generated at startup

## Stop the Production Stack

    docker compose -f infra/docker/prod/docker-compose.yml down

To also remove the PostgreSQL volume:

    docker compose -f infra/docker/prod/docker-compose.yml down -v

## Environment Variables

The stack supports environment-based configuration. Important variables include:

- APP_KEY
- APP_ENV
- APP_DEBUG
- APP_URL
- DATABASE_URL
- DB_CONNECTION
- DB_HOST
- DB_PORT
- DB_DATABASE
- DB_USERNAME
- DB_PASSWORD

In production, prefer setting DATABASE_URL and APP_KEY from your platform secrets manager.

## Deploy on Render

Use the production stack conventions and set runtime environment variables in Render.

Minimum required values:

- APP_KEY
- APP_ENV=production
- APP_DEBUG=false
- DATABASE_URL (from Render PostgreSQL)

Recommended deployment flow:

1. Create a PostgreSQL database in Render.
2. Create a Web Service for this repository.
3. Build and run using the production Docker setup.
4. Add required environment variables in Render dashboard.
5. Deploy and verify application health.

Notes:

- Never hardcode production credentials.
- Use Render-managed PostgreSQL connection details through DATABASE_URL.

## Continuous Integration

CI is defined in:

- .github/workflows/ci.yml

Pipeline includes:

- Composer install
- .env preparation
- APP_KEY generation
- PostgreSQL startup and readiness wait
- Migrations
- Laravel Pint
- PHPStan
- PHPUnit

## Troubleshooting

If startup fails, inspect logs:

    docker compose -f infra/docker/dev/docker-compose.yml logs -f app
    docker compose -f infra/docker/dev/docker-compose.yml logs -f postgres
    docker compose -f infra/docker/dev/docker-compose.yml logs -f nginx

If permissions issues appear on backend files, ensure containers run with your local UID and GID values.
