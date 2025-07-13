#!/bin/bash

# 🚀 Laravel Command Executor for Docker Containers
# This script allows you to run php artisan and composer commands inside the Docker container
# Usage: ./cmd.sh <command>
# Examples:
#   ./cmd.sh php artisan migrate
#   ./cmd.sh php artisan make:controller UserController
#   ./cmd.sh composer install
#   ./cmd.sh composer require laravel/sanctum

set -e

# Container name for this Laravel app
CONTAINER_NAME="payments-app-dev"

# Check if container is running
if ! docker ps --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "❌ Container '${CONTAINER_NAME}' is not running."
    echo "💡 Please start your Docker Compose services first:"
    echo "   cd /Users/lalith/Documents/Projects/shipanything"
    echo "   docker compose up -d"
    exit 1
fi

# Check if command is provided
if [ $# -eq 0 ]; then
    echo "❌ No command provided."
    echo ""
    echo "Usage: $0 <command>"
    echo ""
    echo "Examples:"
    echo "  $0 php artisan migrate"
    echo "  $0 php artisan make:controller UserController"
    echo "  $0 php artisan tinker"
    echo "  $0 composer install"
    echo "  $0 composer require laravel/sanctum"
    echo "  $0 php artisan queue:work"
    exit 1
fi

# Execute the command inside the container
echo "🔧 Executing in container '${CONTAINER_NAME}': $*"
echo "----------------------------------------"
docker exec -it "${CONTAINER_NAME}" "$@"