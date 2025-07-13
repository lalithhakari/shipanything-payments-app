#!/bin/sh

# Laravel Docker startup script - uses shared implementation
# This script redirects to the shared Laravel management script

# Source the shared script
exec /scripts/laravel-manager.sh container-start
