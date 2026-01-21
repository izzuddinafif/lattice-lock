#!/bin/sh
set -e

# Configure nginx to proxy to localhost:8000 (backend in same container)
echo "Configuring nginx to proxy to localhost backend..."

# Create necessary directories for nginx
mkdir -p /var/log/nginx /var/lib/nginx /run

# Set proper permissions
chown -R app:app /var/log/nginx /var/lib/nginx /run 2>/dev/null || true

# Start supervisor
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
