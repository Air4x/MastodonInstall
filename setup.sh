#!/usr/bin/env bash

# script dependencies
apt install -y curl wget gnupg apt-transport-https lsb-release ca-certificates

# node
which node
if [ $? -ne 0 ]; then
    echo "Setting up nodeJS install"
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg 
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
fi
# postgresSQL
which psql
if [ $? -ne 0 ]; then
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
adduser --disable-password mastodon  && echo "[SETUP] mastodon user created"

# creating a user for postgress
echo "In the prompt write:"
echo "CREATE USER mastodon CREATEDB;"
echo "\q"
sudo -u postgres psql

# change to mastodon user
su - mastodon

# cloning mastodon code
git clone https://github.com/mastodon/mastodon.git live && cd live 
git checkout $(git tag -l | grep '^v[0-9.]*$' | sort -V | tail -n 1)

# installing ruby
cd ..
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source  ~/.bashrc
git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build

RUBY_CONFIGURE_OPTS=--with-jemalloc rbenv install

# installing ruby and javascript dependencies
bundle config deployment 'true'
bundle config without 'development test'
bundle install -j$(getconf _NPROCESSORS_ONLN)
yarn install

# generating conf
RAILS_ENV=production bin/rails mastodon:setup

# returning to root
exit
