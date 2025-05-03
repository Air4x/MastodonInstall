#!/usr/bin/env bash
# script dependencies
apt install -y curl wget gnupg apt-transport-https lsb-release ca-certificates

# node
which node
if [ "$(which node)" -ne 0 ]; then
    echo "Setting up nodeJS install"
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg 
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
fi
# postgresSQL
which psql
if [ "$(which psql)" -ne 0 ]; then
    wget -O /usr/share/keyrings/postgresql.asc https://www.postgresql.org/media/keys/ACCC4CF8.asc
    echo "deb [signed-by=/usr/share/keyrings/postgresql.asc] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/postgresql.list
fi

# system pacakges
apt update && echo "[SETUP] update done"
apt install -y \
  imagemagick ffmpeg libvips-tools libpq-dev libxml2-dev libxslt1-dev file git-core \
  g++ libprotobuf-dev protobuf-compiler pkg-config gcc autoconf \
  bison build-essential libssl-dev libyaml-dev libreadline6-dev \
  zlib1g-dev libncurses5-dev libffi-dev libgdbm-dev \
  nginx nodejs redis-server redis-tools postgresql postgresql-contrib \
  certbot python3-certbot-nginx libidn11-dev libicu-dev libjemalloc-dev && echo "[SETUP] updated packages installed"


# Yarn
corepack enable && echo "[SETUP] corepack enable"

# create mastodon use
adduser --disabled-password mastodon  && echo "[SETUP] mastodon user created"

# creating a user for postgress
echo "In the prompt write:"
echo "CREATE USER mastodon CREATEDB;"
echo "\q"
sudo -u postgres psql

# cloning mastodon code
sudo -H -u mastodon -c git clone https://github.com/mastodon/mastodon.git live && cd live
sudo -H -u mastodon -c git checkout "$(git tag -l | grep '^v[0-9.]*$' | sort -V | tail -n 1)"

# installing ruby
sudo -H -u mastodon -c git clone https://github.com/rbenv/rbenv.git ~/.rbenv
sudo -H -u mastodon -c echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
sudo -H -u mastodon -c echo 'eval "$(rbenv init -)"' >> ~/.bashrc
sudo -H -u mastodon -c source  ~/.bashrc
sudo -H -u mastodon -c git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build
sudo -H -u mastodon -c RUBY_CONFIGURE_OPTS=--with-jemalloc rbenv install

# installing ruby and javascript dependencies
sudo -H -u mastodon -c bundle config deployment 'true'
sudo -H -u mastodon -c bundle config without 'development test'
sudo -H -u mastodon -c bundle install -j"$(getconf _NPROCESSORS_ONLN)"
sudo -H -u mastodon -c yarn install

# generating conf
sudo -H -u mastodon -c 'RAILS_ENV=production bin/rails mastodon:setup'

# returning to root
exit
