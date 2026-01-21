#!/bin/sh
set -e

# If BACKEND_URL is set, substitute it in nginx config
if [ -n "$BACKEND_URL" ]; then
    echo "Configuring nginx to proxy to: $BACKEND_URL"
    sed -i "s|http://backend:8000|${BACKEND_URL}|g" /etc/nginx/nginx.conf
fi

# Test nginx config
nginx -t

# Start nginx
exec nginx -g 'daemon off;'
