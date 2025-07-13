#!/bin/bash

# 🚀 Laravel Management Script
# Unified script for all Laravel operations: setup, container startup, and Kubernetes initialization

set -e

# Source shared utilities if available (not available in containers)
if [ -f "$(dirname "${BASH_SOURCE[0]}")/utils.sh" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/utils.sh"
else
    # Define minimal print functions for container environments
    print_info() { echo "ℹ️  $1"; }
    print_success() { echo "✅ $1"; }
    print_warning() { echo "⚠️  $1"; }
    print_error() { echo "❌ $1"; }
    print_step() { echo "🔧 $1"; }
fi

# Laravel applications array
LARAVEL_APPS=("auth-app" "location-app" "payments-app" "booking-app" "fraud-detector-app")

# Function to show usage
show_usage() {
    echo "🚀 Laravel Management Script"
    echo "=========================================="
    echo ""
    echo "Usage: $0 <mode> [app-name]"
    echo ""
    echo "Modes:"
    echo "  setup <app-name>     - Set up Docker configuration for a Laravel app"
    echo "  setup-all           - Set up Docker configuration for all Laravel apps"
    echo "  container-start     - Start Laravel services in container (PHP-FPM + Nginx)"
    echo "  k8s-init            - Initialize Laravel apps in Kubernetes (migrations, cache)"
    echo "  create-all          - Create all Laravel applications from scratch"
    echo ""
    echo "Examples:"
    echo "  $0 setup auth-app              # Setup Docker config for auth-app"
    echo "  $0 setup-all                   # Setup Docker config for all apps"
    echo "  $0 container-start             # Start services in container"
    echo "  $0 k8s-init                    # Initialize apps in Kubernetes"
    echo "  $0 create-all                  # Create all Laravel applications"
    echo ""
}

# Function to get database configuration for an app
get_db_config() {
    local app_name=$1
    case $app_name in
        "auth-app")
            echo "auth-postgres:auth_db:auth_user:auth_password:auth-redis"
            ;;
        "location-app")
            echo "location-postgres:location_db:location_user:location_password:location-redis"
            ;;
        "payments-app")
            echo "payments-postgres:payments_db:payments_user:payments_password:payments-redis"
            ;;
        "booking-app")
            echo "booking-postgres:booking_db:booking_user:booking_password:booking-redis"
            ;;
        "fraud-detector-app")
            echo "fraud-postgres:fraud_db:fraud_user:fraud_password:fraud-redis"
            ;;
        *)
            echo "unknown:unknown:unknown:unknown:unknown"
            ;;
    esac
}

# Function to setup Docker configuration for a Laravel app
setup_laravel_app() {
    local app_name=$1
    local app_dir="/Users/lalith/Documents/Projects/shipanything/microservices/${app_name}"
    
    if [ -z "$app_name" ]; then
        print_error "App name is required for setup mode"
        show_usage
        exit 1
    fi
    
    print_step "Setting up Docker configuration for ${app_name}..."
    
    # Create docker directory
    mkdir -p "${app_dir}/docker"
    
    # Create Nginx configuration
    cat > "${app_dir}/docker/nginx.conf" << 'EOF'
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    # Disable caching for development hot reload
    sendfile off;
    tcp_nopush off;
    tcp_nodelay on;
    
    upstream php-fpm {
        server 127.0.0.1:9000;
    }
    
    server {
        listen 80;
        server_name _;
        root /var/www/html/public;
        index index.php index.html;
        
        # Disable all caching for development
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
        
        location / {
            try_files $uri $uri/ /index.php?$query_string;
        }
        
        location ~ \.php$ {
            fastcgi_pass php-fpm;
            fastcgi_index index.php;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            include fastcgi_params;
            
            # Disable FastCGI caching for development
            fastcgi_cache off;
            fastcgi_no_cache 1;
            fastcgi_cache_bypass 1;
        }
        
        location ~ /\.ht {
            deny all;
        }
    }
}
EOF
    
    # Create PHP-FPM configuration
    cat > "${app_dir}/docker/php-fpm.conf" << 'EOF'
[www]
user = www-data
group = www-data
listen = 127.0.0.1:9000
listen.owner = www-data
listen.group = www-data
pm = dynamic
pm.max_children = 20
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
EOF
    
    # Create startup script that calls this unified script
    cat > "${app_dir}/docker/start.sh" << 'EOF'
#!/bin/sh

# Laravel Docker startup script - uses shared implementation
# This script redirects to the shared Laravel management script

# Source the shared script
exec /scripts/laravel-manager.sh container-start
EOF
    
    chmod +x "${app_dir}/docker/start.sh"
    
    # Copy this script to the docker directory so it's available during Docker build
    cp "$(realpath "${BASH_SOURCE[0]}")" "${app_dir}/docker/laravel-manager.sh"
    chmod +x "${app_dir}/docker/laravel-manager.sh"
    
    # Update Laravel .env for containerized environment
    if [ -f "${app_dir}/.env" ]; then
        local db_config=$(get_db_config "$app_name")
        IFS=':' read -r db_host db_name db_user db_pass redis_host <<< "$db_config"
        
        print_step "Updating .env configuration for ${app_name}..."
        sed -i '' "s/DB_HOST=.*/DB_HOST=${db_host}/" "${app_dir}/.env"
        sed -i '' "s/DB_DATABASE=.*/DB_DATABASE=${db_name}/" "${app_dir}/.env"
        sed -i '' "s/DB_USERNAME=.*/DB_USERNAME=${db_user}/" "${app_dir}/.env"
        sed -i '' "s/DB_PASSWORD=.*/DB_PASSWORD=${db_pass}/" "${app_dir}/.env"
        sed -i '' "s/REDIS_HOST=.*/REDIS_HOST=${redis_host}/" "${app_dir}/.env"
        
        # Add Kafka configuration
        if ! grep -q "KAFKA_BROKERS" "${app_dir}/.env"; then
            echo "" >> "${app_dir}/.env"
            echo "# Kafka Configuration" >> "${app_dir}/.env"
            echo "KAFKA_BROKERS=kafka:29092" >> "${app_dir}/.env"
        fi
    fi
    
    print_success "Docker configuration for ${app_name} completed!"
}

# Function to setup all Laravel applications
setup_all_apps() {
    print_step "Setting up Docker configuration for all Laravel applications..."
    
    for app in "${LARAVEL_APPS[@]}"; do
        if [ -d "/Users/lalith/Documents/Projects/shipanything/microservices/$app" ]; then
            setup_laravel_app "$app"
        else
            print_warning "Directory for $app does not exist, skipping..."
        fi
    done
    
    print_success "🎉 Docker configuration completed for all Laravel applications!"
}

# Function to start Laravel services in container
container_start() {
    print_step "Starting Laravel services in container..."
    
    # Create .env file if it doesn't exist
    if [ ! -f /var/www/html/.env ]; then
        print_step "Creating .env file from example..."
        cp /var/www/html/.env.example /var/www/html/.env
    fi
    
    # Generate APP_KEY if not set in environment
    if [ -z "$APP_KEY" ]; then
        print_step "Generating Laravel application key..."
        php artisan key:generate --no-interaction --force
    fi
    
    # Install Composer dependencies if vendor directory is missing
    if [ ! -d /var/www/html/vendor ]; then
        print_step "Installing Composer dependencies..."
        composer install --no-interaction
    fi
    
    # Set proper permissions
    chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
    chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache
    
    # Wait for database to be ready
    print_step "Waiting for database connection..."
    max_attempts=30
    attempt=0
    while [ $attempt -lt $max_attempts ]; do
        if php artisan migrate:status --no-interaction >/dev/null 2>&1; then
            print_success "Database connection established"
            break
        elif php -r "new PDO('pgsql:host='.\$_ENV['DB_HOST'].';port='.\$_ENV['DB_PORT'].';dbname='.\$_ENV['DB_DATABASE'], \$_ENV['DB_USERNAME'], \$_ENV['DB_PASSWORD']);" 2>/dev/null; then
            print_success "Database connection established, running migrations..."
            php artisan migrate --force --no-interaction
            break
        else
            attempt=$((attempt + 1))
            print_step "Waiting for database... ($attempt/$max_attempts)"
            sleep 5
        fi
    done
    
    if [ $attempt -eq $max_attempts ]; then
        print_warning "Database connection timeout, starting anyway..."
    fi
    
    # Run migrations if database is available
    print_step "Running database migrations..."
    php artisan migrate --force --no-interaction || print_warning "Migrations failed, continuing..."
    
    # Clear all Laravel caches in container mode (mode 1) to ensure hot reload works
    print_info "Clearing Laravel caches to ensure hot reload works in development mode"
    
    # Clear all possible Laravel caches
    php artisan config:clear --no-interaction || print_warning "Config clear failed"
    php artisan route:clear --no-interaction || print_warning "Route clear failed"  
    php artisan view:clear --no-interaction || print_warning "View clear failed"
    php artisan cache:clear --no-interaction || print_warning "Application cache clear failed"
    
    # Also clear opcache if available to ensure PHP file changes are reflected
    php artisan optimize:clear --no-interaction || print_warning "Optimize clear failed"
    
    # Ensure we're in development mode by setting APP_ENV if not already set
    if ! grep -q "APP_ENV=local" /var/www/html/.env 2>/dev/null; then
        print_step "Setting application to local development mode..."
        if grep -q "APP_ENV=" /var/www/html/.env 2>/dev/null; then
            sed -i 's/APP_ENV=.*/APP_ENV=local/' /var/www/html/.env
        else
            echo "APP_ENV=local" >> /var/www/html/.env
        fi
    fi
    
    # Ensure APP_DEBUG is enabled for development
    if ! grep -q "APP_DEBUG=true" /var/www/html/.env 2>/dev/null; then
        print_step "Enabling debug mode for development..."
        if grep -q "APP_DEBUG=" /var/www/html/.env 2>/dev/null; then
            sed -i 's/APP_DEBUG=.*/APP_DEBUG=true/' /var/www/html/.env
        else
            echo "APP_DEBUG=true" >> /var/www/html/.env
        fi
    fi
    
    print_success "Laravel caches cleared - hot reload enabled"
    
    # Start PHP-FPM in background
    print_step "Starting PHP-FPM..."
    php-fpm -D
    
    # Verify PHP-FPM started
    if ! pgrep php-fpm > /dev/null; then
        print_error "PHP-FPM failed to start!"
        exit 1
    fi
    print_success "PHP-FPM started successfully"
    
    # Test Nginx configuration
    print_step "Testing Nginx configuration..."
    nginx -t
    
    if [ $? -eq 0 ]; then
        print_success "Nginx configuration test passed"
        # Start Nginx in foreground
        print_step "Starting Nginx..."
        exec nginx -g "daemon off;"
    else
        print_error "Nginx configuration test failed!"
        exit 1
    fi
}

# Function to initialize Laravel apps in Kubernetes
k8s_init() {
    print_step "Initializing Laravel Applications in Kubernetes..."
    
    # Wait for all databases to be ready
    print_info "Waiting for databases to be ready..."
    for app in "${LARAVEL_APPS[@]}"; do
        db_name="${app%-app}"
        kubectl wait --for=condition=ready pod -l app=${db_name}-postgres -n shipanything --timeout=300s
        print_success "Database for $app is ready"
    done
    
    # Initialize each Laravel application
    for app in "${LARAVEL_APPS[@]}"; do
        print_info "Initializing Laravel application: $app"
        
        # Get the first pod for this app
        POD=$(kubectl get pods -n shipanything -l app=$app -o jsonpath="{.items[0].metadata.name}" 2>/dev/null || echo "")
        
        if [ -z "$POD" ]; then
            print_warning "No pods found for $app, skipping initialization"
            continue
        fi
        
        print_info "Found pod: $POD for $app"
        
        # Wait for pod to be ready
        kubectl wait --for=condition=ready pod/$POD -n shipanything --timeout=120s
        
        # Run Laravel migrations
        print_info "Running migrations for $app..."
        kubectl exec -n shipanything $POD -- php artisan migrate --force || print_warning "Migration failed for $app (may be expected for fresh install)"
        
        # Clear and cache Laravel configuration (Kubernetes production optimization)
        print_info "Optimizing Laravel configuration for $app..."
        kubectl exec -n shipanything $POD -- php artisan config:cache || print_warning "Config cache failed for $app"
        kubectl exec -n shipanything $POD -- php artisan route:cache || print_warning "Route cache failed for $app"
        kubectl exec -n shipanything $POD -- php artisan view:cache || print_warning "View cache failed for $app"
        
        print_success "Initialization completed for $app"
    done
    
    print_success "🎉 All Laravel applications initialized successfully!"
    print_info "Applications are now ready to receive traffic."
}

# Function to create all Laravel applications
create_all_apps() {
    print_step "Creating all Laravel applications for ShipAnything..."
    
    # Change to microservices directory
    cd "$(dirname "$0")/../microservices"
    
    # Create each Laravel application
    for app in "${LARAVEL_APPS[@]}"; do
        if [ ! -d "$app" ]; then
            print_info "Creating Laravel application: $app"
            print_warning "Please manually select options for $app when prompted"
            laravel new "$app"
            
            print_info "Setting up Docker configuration for $app..."
            "$(dirname "$0")/laravel-manager.sh" setup "$app"
            
            print_success "Completed setup for $app"
            echo ""
        else
            print_warning "$app already exists, skipping creation"
        fi
    done
    
    print_success "🎉 All Laravel applications have been created!"
    print_info "Next steps:"
    echo "  1. Review the generated Laravel applications"
    echo "  2. Run ./scripts/deploy.sh to deploy to Kubernetes"
}

# Main script logic
case "${1:-}" in
    "setup")
        setup_laravel_app "$2"
        ;;
    "setup-all")
        setup_all_apps
        ;;
    "container-start")
        container_start
        ;;
    "k8s-init")
        k8s_init
        ;;
    "create-all")
        create_all_apps
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
