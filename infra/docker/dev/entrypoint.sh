#!/usr/bin/env sh
set -eu

APP_ROOT="/var/www"

set_env_var() {
    key="$1"
    value="$2"
    file="$3"

    escaped_value=$(printf '%s' "$value" | sed 's/[&|]/\\&/g')

    if grep -q "^${key}=" "$file"; then
        sed -i "s|^${key}=.*|${key}=${escaped_value}|" "$file"
    else
        printf '\n%s=%s\n' "$key" "$value" >> "$file"
    fi
}

wait_for_postgres() {
    retries="$1"
    sleep_seconds="$2"
    current_try=1

    while [ "$current_try" -le "$retries" ]; do
        if php -r '
            $host = getenv("DB_HOST") ?: "postgres";
            $port = getenv("DB_PORT") ?: "5432";
            $database = getenv("DB_DATABASE") ?: "ligue1";
            $username = getenv("DB_USERNAME") ?: "laravel";
            $password = getenv("DB_PASSWORD") ?: "laravel";

            try {
                new PDO(
                    "pgsql:host={$host};port={$port};dbname={$database}",
                    $username,
                    $password,
                    [PDO::ATTR_TIMEOUT => 3]
                );
                exit(0);
            } catch (Throwable $exception) {
                fwrite(STDERR, "PostgreSQL not ready yet.\n");
                exit(1);
            }
        '; then
            return 0
        fi

        echo "Waiting for PostgreSQL (${current_try}/${retries})..."
        current_try=$((current_try + 1))
        sleep "$sleep_seconds"
    done

    echo "PostgreSQL is not reachable after ${retries} attempts."
    return 1
}

cd "$APP_ROOT"

if [ -z "$(find . -mindepth 1 -maxdepth 1 -not -name '.gitkeep' -print -quit)" ]; then
    echo "No Laravel project found in ${APP_ROOT}. Creating a fresh Laravel application..."
    composer create-project laravel/laravel . --no-interaction --prefer-dist
else
    echo "Existing Laravel project detected. Installing Composer dependencies..."
    composer install --no-interaction --prefer-dist
fi

if [ ! -f .env ]; then
    cp .env.example .env
fi

: "${APP_ENV:=local}"
: "${APP_DEBUG:=true}"
: "${APP_URL:=http://localhost}"
: "${DB_CONNECTION:=pgsql}"
: "${DB_HOST:=postgres}"
: "${DB_PORT:=5432}"
: "${DB_DATABASE:=ligue1}"
: "${DB_USERNAME:=laravel}"
: "${DB_PASSWORD:=laravel}"
: "${DB_WAIT_RETRIES:=60}"
: "${DB_WAIT_SLEEP:=2}"

set_env_var "APP_ENV" "$APP_ENV" .env
set_env_var "APP_DEBUG" "$APP_DEBUG" .env
set_env_var "APP_URL" "$APP_URL" .env
set_env_var "DB_CONNECTION" "$DB_CONNECTION" .env
set_env_var "DB_HOST" "$DB_HOST" .env
set_env_var "DB_PORT" "$DB_PORT" .env
set_env_var "DB_DATABASE" "$DB_DATABASE" .env
set_env_var "DB_USERNAME" "$DB_USERNAME" .env
set_env_var "DB_PASSWORD" "$DB_PASSWORD" .env

app_key_line=$(grep '^APP_KEY=' .env || true)
if [ -z "$app_key_line" ] || [ "$app_key_line" = "APP_KEY=" ]; then
    php artisan key:generate --no-interaction
fi

wait_for_postgres "$DB_WAIT_RETRIES" "$DB_WAIT_SLEEP"

php artisan migrate --force --no-interaction

exec php-fpm
