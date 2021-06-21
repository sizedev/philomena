# Distro requirements
# Debian
#   sudo apt-get install -y postgresql postgresql-client libpng-dev libmagic-dev libavformat-dev libswscale-dev
# Alpine Linux
#   apk add inotify-tools build-base git ffmpeg ffmpeg-dev npm nodejs file-dev libpng-dev gifsicle optipng libjpeg-turbo-utils librsvg imagemagick postgresql-client wget
mix local.hex --force
mix local.rebar --force

# PostgreSQL server setup
#   sudo -u postgres createuser swbooru
#   sudo -u postgres psql -c "ALTER USER swbooru CREATEDB"

#!/usr/bin/env sh
rm -rf /tmp/cli_intensities
git clone https://github.com/philomena-dev/cli_intensities /tmp/cli_intensities \
&& cd /tmp/cli_intensities \
&& PREFIX=~ make -j$(nproc) install

rm -rf /tmp/mediatools
git clone https://github.com/philomena-dev/mediatools /tmp/mediatools \
&& cd /tmp/mediatools \
&& PREFIX=~ make -j$(nproc) install

# Always install assets
(cd ~/philomena/assets && npm install)

# Always install mix dependencies
(cd ~/philomena && mix deps.get)

# Try to create the database if it doesn't exist yet
createdb swbooru && mix ecto.setup && mix reindex_all
