#!/bin/sh

# Laravel Docker startup script

# Create .env file if it doesn't exist
if [ ! -f /var/www/html/.env ]; then
    echo "Creating .env file from example..."
    cp /var/www/html/.env.example /var/www/html/.env
fi

# Set proper permissions
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Generate APP_KEY if not set
if [ -z "$APP_KEY" ] || [ "$APP_KEY" = "base64:" ]; then
    echo "Generating Laravel application key..."
    php artisan key:generate --force --no-interaction
fi

# Wait for database to be ready (simple wait since we know infrastructure is running)
echo "Waiting for database to be ready..."
sleep 30
echo "Database should be ready now!"

# Run database migrations
echo "Running database migrations..."
php artisan migrate --force --no-interaction || echo "Migration failed, continuing..."

# Cache Laravel configuration
echo "Optimizing Laravel..."
php artisan config:cache --no-interaction
php artisan route:cache --no-interaction || echo "Route cache skipped (no routes defined yet)"
php artisan view:cache --no-interaction || echo "View cache skipped"

# Start PHP-FPM in background
echo "Starting PHP-FPM..."
php-fpm -D

# Verify PHP-FPM started
if ! pgrep php-fpm > /dev/null; then
    echo "ERROR: PHP-FPM failed to start!"
    exit 1
fi
echo "PHP-FPM started successfully"

# Test Nginx configuration
echo "Testing Nginx configuration..."
nginx -t
if [ $? -ne 0 ]; then
    echo "ERROR: Nginx configuration test failed!"
    exit 1
fi

# Start Nginx in foreground
echo "Starting Nginx..."
exec nginx -g "daemon off;"
