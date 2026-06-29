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

resolve_database_env_from_url() {
    if [ -z "${DATABASE_URL:-}" ]; then
        return 0
    fi

    parsed_values=$(php -r '
        $url = getenv("DATABASE_URL") ?: "";
        if ($url === "") {
            exit(0);
        }

        $parts = parse_url($url);
        if ($parts === false) {
            fwrite(STDERR, "Invalid DATABASE_URL.\n");
            exit(1);
        }

        $scheme = $parts["scheme"] ?? "pgsql";
        if ($scheme === "postgres" || $scheme === "postgresql") {
            $scheme = "pgsql";
        }
        $host = $parts["host"] ?? "";
        $port = (string)($parts["port"] ?? 5432);
        $database = isset($parts["path"]) ? ltrim($parts["path"], "/") : "";
        $username = $parts["user"] ?? "";
        $password = $parts["pass"] ?? "";

        echo "DB_CONNECTION={$scheme}\n";
        echo "DB_HOST={$host}\n";
        echo "DB_PORT={$port}\n";
        echo "DB_DATABASE={$database}\n";
        echo "DB_USERNAME={$username}\n";
        echo "DB_PASSWORD={$password}\n";
    ')

    if [ -n "$parsed_values" ]; then
        while IFS='=' read -r key value; do
            case "$key" in
                DB_CONNECTION) DB_CONNECTION="$value" ;;
                DB_HOST) DB_HOST="$value" ;;
                DB_PORT) DB_PORT="$value" ;;
                DB_DATABASE) DB_DATABASE="$value" ;;
                DB_USERNAME) DB_USERNAME="$value" ;;
                DB_PASSWORD) DB_PASSWORD="$value" ;;
            esac
        done <<EOF
$parsed_values
EOF
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

if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        cp .env.example .env
    else
        touch .env
    fi
fi

: "${APP_ENV:=production}"
: "${APP_DEBUG:=false}"
: "${APP_URL:=http://localhost}"
: "${APP_KEY:=}"
: "${DATABASE_URL:=}"
: "${DB_CONNECTION:=pgsql}"
: "${DB_HOST:=postgres}"
: "${DB_PORT:=5432}"
: "${DB_DATABASE:=ligue1}"
: "${DB_USERNAME:=laravel}"
: "${DB_PASSWORD:=laravel}"
: "${DB_WAIT_RETRIES:=60}"
: "${DB_WAIT_SLEEP:=2}"
: "${RUN_MIGRATIONS:=true}"

resolve_database_env_from_url

set_env_var "APP_ENV" "$APP_ENV" .env
set_env_var "APP_DEBUG" "$APP_DEBUG" .env
set_env_var "APP_URL" "$APP_URL" .env
set_env_var "DB_CONNECTION" "$DB_CONNECTION" .env
set_env_var "DB_HOST" "$DB_HOST" .env
set_env_var "DB_PORT" "$DB_PORT" .env
set_env_var "DB_DATABASE" "$DB_DATABASE" .env
set_env_var "DB_USERNAME" "$DB_USERNAME" .env
set_env_var "DB_PASSWORD" "$DB_PASSWORD" .env

if [ -n "$DATABASE_URL" ]; then
    set_env_var "DATABASE_URL" "$DATABASE_URL" .env
fi

if [ -n "$APP_KEY" ]; then
    set_env_var "APP_KEY" "$APP_KEY" .env
else
    app_key_line=$(grep '^APP_KEY=' .env || true)
    if [ -z "$app_key_line" ] || [ "$app_key_line" = "APP_KEY=" ]; then
        php artisan key:generate --no-interaction
    fi
fi

if [ "$DB_CONNECTION" = "pgsql" ]; then
    wait_for_postgres "$DB_WAIT_RETRIES" "$DB_WAIT_SLEEP"
fi

if [ "$RUN_MIGRATIONS" = "true" ]; then
    php artisan migrate --force --no-interaction
fi

php artisan config:cache --no-interaction
php artisan route:cache --no-interaction
php artisan event:cache --no-interaction
php artisan view:cache --no-interaction

exec php-fpm
