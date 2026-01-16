#!/bin/sh
set -e

echo "=== Railway Entrypoint ==="
echo "Environment: ${ENV:-production}"

# Run migrations if DATABASE_URL is set
if [ -n "$DATABASE_URL" ]; then
    echo "Running database migrations..."

    for migration in /app/migrations/*.up.sql; do
        if [ -f "$migration" ]; then
            echo "Applying: $(basename $migration)"
            # Use psql if available, otherwise skip
            if command -v psql > /dev/null 2>&1; then
                psql "$DATABASE_URL" -f "$migration" 2>&1 || echo "Migration may already be applied: $(basename $migration)"
            else
                echo "psql not available - migrations will be handled by app"
            fi
        fi
    done

    echo "Migrations complete"
else
    echo "DATABASE_URL not set - skipping migrations"
fi

echo "Starting application..."
exec "$@"
