#!/usr/bin/env sh
git clone https://github.com/philomena-dev/cli_intensities /tmp/cli_intensities \
&& cd /tmp/cli_intensities \
&& make -j$(nproc) install

git clone https://github.com/philomena-dev/mediatools /tmp/mediatools \
&& cd /tmp/mediatools \
&& make -j$(nproc) install

# Always install assets
(cd /srv/philomena/assets && npm install)

# Always install mix dependencies
(cd /srv/philomena && mix deps.get)

# Try to create the database if it doesn't exist yet
createdb -h postgres -U postgres philomena && mix ecto.setup && mix reindex_all
