#!/bin/bash

# Wait for database to be ready
until pg_isready -h db -U postgres > /dev/null 2>&1; do
  echo "Waiting for database to be ready..."
  sleep 2
done

# Create database if it doesn't exist
echo "Creating database if needed..."
bundle exec rails db:create 2>/dev/null || true

# Run migrations (don't fail container if migrations fail - user can fix manually)
echo "Running database migrations..."
if bundle exec rails db:migrate; then
  echo "Migrations completed successfully"
else
  echo "WARNING: Migrations failed. You may need to fix them manually."
  echo "Run 'docker compose exec web bundle exec rails db:migrate' to retry."
fi

# Build JavaScript assets (don't fail container if build fails)
echo "Building JavaScript assets..."
if yarn build; then
  echo "JavaScript assets built successfully"
else
  echo "WARNING: JavaScript build failed. You can run 'yarn build' manually later."
fi

# Execute the command passed to the container
exec "$@"

