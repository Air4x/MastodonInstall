#!/usr/bin/env bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <domain>"
    exit 1
fi
# Obtain certificates
certbot certonly --nginx -d $1

# Setup nginx
cp /home/mastodon/live/dist/nginx.conf /etc/nginx/sites-available/mastodon
ln -s /etc/nginx/sites-available/mastodon /etc/nginx/sites-enabled/mastodon
rm /etc/nginx/sites-enabled/default

# Setup nginx config
echo "Edit /etc/nginx/sites-available/mastodon"
echo "to ensure that the correct domain is used"
echo "and uncomment the ssl_certificates and"
echo "ssl_certificate_key lines"

chmod o+x /home/mastodon
systemctl restart nginx

# Setup systemd services and start them
cp /home/mastodon/live/dist/mastodon-*.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now mastodon-web mastodon-sidekiq mastodon-streaming
