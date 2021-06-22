#!/usr/bin/env bash

# Set up environment
source ~/bin/philomena-env

# Sleep to allow Elasticsearch to finish initializing
# if it's not done doing whatever it does yet
echo -n "Waiting for Elasticsearch"

until wget -qO- $ELASTICSEARCH_URL > /dev/null; do
  echo -n "."
  sleep 2
done

echo
echo "Elasticsearch ready"

background() {
  while :; do
    mix run -e 'Philomena.Release.update_channels()'
    mix run -e 'Philomena.Release.verify_artist_links()'
    mix run -e 'Philomena.Release.update_stats()'

    sleep 300
  done
}

echo "Starting background jobs"

# Run background jobs
# background &

echo "Starting booru app"

# Run the application
START_WORKER=true exec mix phx.server
