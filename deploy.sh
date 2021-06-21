#!/usr/bin/env bash

# Set up environment
source ~/bin/philomena-env

echo "Deploying"

cd ~/philomena

die() {
    echo "$*" 1>&2
    exit 1
}

echo "Fetching deps"
mix deps.get || die "mix failed to update"

echo "Compiling assets"
npm install --prefix ./assets || die "assets install failed"
npm run deploy --prefix ./assets
mix phx.digest || die "assets compile failed"

echo "Building release"
mix release --overwrite || die "failed to generate release"

echo "Running database migrations"
_build/prod/rel/philomena/bin/philomena eval "Philomena.Release.migrate()" || die "ecto.migrate failed"

# Include a task to restart your running appserver instances here.
#
# In general, you should have many app instances configured on different
# ports using the PORT environment variable, so as to allow you to roll
# releases and deploy new code with no visible downtime.
#
# You can use a reverse proxy like haproxy or nginx to load balance between
# different server instances automatically.
