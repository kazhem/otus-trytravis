#!/bin/bash

# Add mongo repository
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0xd68fa50fea312927
echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse" > /etc/apt/sources.list.d/mongodb-org-3.2.list
apt update && apt upgrade
# Install Ruby and Mongo
apt install -y ruby-full ruby-bundler build-essential mongodb-org
# Install redit app
git clone -b monolith https://github.com/express42/reddit.git /opt/reddit
cd /opt/reddit; bundle install
# Enable services
cp /tmp/puma.service /etc/systemd/system/puma.service
systemctl enable mongod
systemctl enable puma
