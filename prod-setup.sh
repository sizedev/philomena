# Distro requirements
# Debian
#   sudo apt-get install -y postgresql postgresql-client libpng-dev libmagic-dev
# Alpine Linux
#   apk add inotify-tools build-base git ffmpeg ffmpeg-dev npm nodejs file-dev libpng-dev gifsicle optipng libjpeg-turbo-utils librsvg imagemagick postgresql-client wget
mix local.hex --force
mix local.rebar --force

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
createdb -h postgres -U postgres philomena && mix ecto.setup && mix reindex_all
