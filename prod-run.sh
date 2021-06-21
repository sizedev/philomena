#!/usr/bin/env bash

# Set up environment
source ~/bin/philomena-env

# Sleep to allow Elasticsearch to finish initializing
# if it's not done doing whatever it does yet
echo -n "Waiting for Elasticsearch"

until wget -qO- $ELASTICSEARCH_URL; do
  echo -n "."
  sleep 2
done

echo

background() {
  while :; do
    mix run -e 'Philomena.Release.update_channels()'
    mix run -e 'Philomena.Release.verify_artist_links()'
    mix run -e 'Philomena.Release.update_stats()'

    sleep 300
  done
}

# Run background jobs
background &

# Run the application
START_WORKER=true exec mix phx.server
