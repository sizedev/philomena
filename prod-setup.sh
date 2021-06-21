#!/usr/bin/env sh

# Distro requirements
# Debian
#   sudo apt-get install -y postgresql postgresql-client libpng-dev libmagic-dev libavformat-dev libswscale-dev
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
rm -rf /tmp/cli_intensities
git clone https://github.com/philomena-dev/cli_intensities /tmp/cli_intensities \
&& cd /tmp/cli_intensities \
&& PREFIX=~ make -j$(nproc) install

echo
echo Installing mediatools
rm -rf /tmp/mediatools
git clone https://github.com/philomena-dev/mediatools /tmp/mediatools \
&& cd /tmp/mediatools \
&& PREFIX=~ make -j$(nproc) install

# Always install assets
echo
echo Installing assets
cd ~/philomena/assets
npm install

# Always install mix dependencies
echo
echo Installing mix deps
cd ~/philomena
mix deps.get

echo
echo Installing database
# Try to create the database if it doesn't exist yet
createdb swbooru && mix ecto.setup && mix reindex_all
