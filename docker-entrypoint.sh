#!/bin/sh
set -e

# If BACKEND_URL is set, substitute it in nginx config
# If not set, comment out the proxy_pass so nginx can start (API won't work)
if [ -n "$BACKEND_URL" ]; then
    echo "Configuring nginx to proxy to: $BACKEND_URL"
    sed -i "s|http://backend:8000|${BACKEND_URL}|g" /etc/nginx/nginx.conf
else
    echo "WARNING: BACKEND_URL not set - API proxy will be disabled"
    sed -i "s|proxy_pass http://backend:8000;|#proxy_pass http://backend:8000; # BACKEND_URL not set|g" /etc/nginx/nginx.conf
fi

# Test nginx config
nginx -t

# Start nginx
exec nginx -g 'daemon off;'
