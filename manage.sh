#!/bin/bash
# manage.sh

# A simple script to manage my home lab Docker Compose stack

# Load environment variables from .env file
if [ -f .env ]; then
  export $(cat .env | sed 's/#.*//g' | xargs)
fi

# Check for required variables
if [ -z "$PIHOLE_PASSWORD" ]; then
  echo "Error: PIHOLE_PASSWORD is not set in the .env file."
  exit 1
fi

case "$1" in
  start)
    echo "Starting home lab services..."
    docker compose up -d
    ;;
  stop)
    echo "Stopping home lab services..."
    docker compose down
    ;;
  logs)
    echo "Tailing logs for all services..."
    docker compose logs -f
    ;;
  update)
    echo "Updating all service images..."
    docker compose pull
    docker compose up -d --force-recreate
    echo "Update complete."
    ;;
  *)
    echo "Usage: $0 {start|stop|logs|update}"
    exit 1
    ;;
esac

exit 0
