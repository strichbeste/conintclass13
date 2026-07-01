#!/bin/bash
# Blue-Green switch script
# Reads current active config and switches to the other one

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NGINX_CONF_DIR="$SCRIPT_DIR/../nginx"
ACTIVE_CONF="/etc/nginx/conf.d/active.conf"

# Determine which config is currently mounted (check nginx container)
CURRENT=$(docker compose exec nginx cat /etc/nginx/conf.d/active.conf | grep 'server app-' | awk '{print $2}' | cut -d':' -f1)

if [[ "$CURRENT" == *"blue"* ]]; then
  echo "Currently BLUE → switching to GREEN"
  cp "$NGINX_CONF_DIR/green.conf" "$NGINX_CONF_DIR/active.conf.tmp"
  mv "$NGINX_CONF_DIR/active.conf.tmp" "$NGINX_CONF_DIR/active.conf"
  # Re-create bind mount by updating the volume source
  docker compose up -d --no-deps nginx
  echo "Switched to GREEN ✅"
else
  echo "Currently GREEN → switching to BLUE"
  cp "$NGINX_CONF_DIR/blue.conf" "$NGINX_CONF_DIR/active.conf.tmp"
  mv "$NGINX_CONF_DIR/active.conf.tmp" "$NGINX_CONF_DIR/active.conf"
  docker compose up -d --no-deps nginx
  echo "Switched to BLUE ✅"
fi

# Reload nginx config without downtime
docker compose exec --interactive --tty nginx nginx -s reload
echo "Nginx reloaded ✅"
