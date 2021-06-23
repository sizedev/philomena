#!/usr/bin/env bash

die() {
    echo "$*" 1>&2
    exit 1
}

# Set up environment
source ~/bin/philomena-env \
|| die "Failed to set up environment"

echo "Setting up"

cd ~/philomena

# Distro requirements
# Debian
#   sudo apt-get install -y ffmpeg file libpng-dev gifsicle optipng libjpeg-turbo-progs librsvg2-bin libmagic-dev libavformat-dev libswscale-dev redis-server postgresql postgresql-client wget elasticsearch
# Alpine Linux
#   apk add inotify-tools build-base git ffmpeg ffmpeg-dev npm nodejs file-dev libpng-dev gifsicle optipng libjpeg-turbo-utils librsvg imagemagick postgresql-client wget
echo Installing requirements
mix local.hex --force
mix local.rebar --force

# PostgreSQL server setup
#   sudo -u postgres createuser swbooru
#   sudo -u postgres psql -c "ALTER USER swbooru CREATEDB"

echo
echo Installing cli_intensities
rm -rf /tmp/cli_intensities \
&& git clone https://github.com/philomena-dev/cli_intensities /tmp/cli_intensities \
&& cd /tmp/cli_intensities \
&& PREFIX=~ make -j$(nproc) install \
|| die "Failed to install cli_intensities"

echo
echo Installing mediatools
rm -rf /tmp/mediatools
git clone https://github.com/philomena-dev/mediatools /tmp/mediatools \
&& cd /tmp/mediatools \
&& PREFIX=~ make -j$(nproc) install \
|| die "Failed to install mediatools"

# Always install assets
echo
echo Installing assets
cd ~/philomena/assets \
&& npm install \
|| die "Failed to install assets"

# Always install mix dependencies
echo
echo Installing mix deps
cd ~/philomena \
&& mix deps.get \
|| die "Failed to install mix dependencies"

echo
echo Installing database
# Delete database if necessary
psql -d postgres -c 'DROP DATABASE swbooru'
# Try to create the database if it doesn't exist yet
PGHOST=$DATABASE_HOST PGUSER=$DATABASE_USER PGPASSWORD=$DATABASE_PW createdb $DATABASE_DB \
&& mix ecto.setup \
&& mix reindex_all --i-know-what-im-doing \
|| die "Failed to install database"
