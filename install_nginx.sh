#!/usr/bin/bash

echo "Nginx installation initiated..."

# Installing base on IP or Domain
read -p "Please Enter your domain: " -e -i "example.com" address

# Update and install necessary packages
sudo apt update
sudo apt install -y nginx certbot python3-certbot-nginx

# Obtain SSL certificates using Certbot
sudo certbot --nginx -d "$address"

# Restart nginx to apply changes
sudo systemctl restart nginx

# Enable automatic renewal of certificates
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer

# Schedule a cron job for renewal check
(crontab -l ; echo "0 0 * * * certbot renew --quiet --no-self-upgrade") | crontab -