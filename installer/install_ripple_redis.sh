#!/usr/bin/env bash

# run using: source install_ripple.sh

# run as normal user, eg ubuntu

# 20 June 2017


# Prepare

echo 'Preparing environment'

sudo apt-get update
sudo apt-get install -y build-essential libssl-dev
sudo apt-get install -y wget gzip openssh-server curl python-minimal unzip

# Node.js

echo 'Installing Node.js'

cd ~

curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.32.1/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" # This loads nvm
nvm install 6

#make Node.js available to sudo

sudo ln -s /usr/local/bin/node /usr/bin/node
sudo ln -s /usr/local/lib/node /usr/lib/node
sudo ln -s /usr/local/bin/npm /usr/bin/npm
sudo ln -s /usr/local/bin/node-waf /usr/bin/node-waf
n=$(which node);n=${n%/bin/node}; chmod -R 755 $n/bin/*; sudo cp -r $n/{bin,lib,share} /usr/local

# QEWD

cd ~
mkdir qewd
cd qewd

# Install qewd-ripple (and its dependencies)

cd ~/qewd
npm install qewd-ripple ewd-client
npm install tcp-netx
npm install ewd-redis-globals
sudo npm install -g pm2


echo 'Moving qewd-ripple and QEWD files into place'

mv ~/qewd/node_modules/qewd-ripple/example/ripple-demo-redis.js ~/qewd/ripple-demo.js
mv ~/qewd/node_modules/qewd-ripple/example/ripple-secure-redis.js ~/qewd/ripple-secure.js

cd ~/qewd
mkdir www
cd www
mkdir qewd-monitor
mkdir qewd-content-store

cp ~/qewd/node_modules/qewd-monitor/www/bundle.js ~/qewd/www/qewd-monitor
cp ~/qewd/node_modules/qewd-monitor/www/*.html ~/qewd/www/qewd-monitor
cp ~/qewd/node_modules/qewd-monitor/www/*.css ~/qewd/www/qewd-monitor

cp ~/qewd/node_modules/qewd-content-store/www/bundle.js ~/qewd/www/qewd-content-store
cp ~/qewd/node_modules/qewd-content-store/www/*.html ~/qewd/www/qewd-content-store

cp ~/qewd/node_modules/ewd-client/lib/proto/ewd-client.js ~/qewd/www/ewd-client.js

# ============ WebRTC installation ========

# Server

cp -r ~/qewd/node_modules/qewd-ripple/webrtc/server/ ~/videochat-socket-server/
cp -r ~/qewd/node_modules/qewd-ripple/webrtc/ssl/ ~/qewd/ssl/
cd ~/videochat-socket-server
npm install
pm2 start pm2.json
pm2 save

# Client

# cp -r ~/qewd/node_modules/qewd-ripple/webrtc/client/ ~/qewd/www/videochat/
#   this is copied from the client s/w repository later

# TURN Server

# Optional - uncomment if needed
#  You'll also need to change the turnServer definition
#  at the top of ~/qewd/www/videochat/videochat.js

# cd ~/qewd/node_modules/qewd-ripple/webrtc/turn
# echo 'deb http://http.us.debian.org/debian jessie main' | sudo tee /etc/apt/sources.list.d/coturn.list
# gpg --keyserver pgpkeys.mit.edu --recv-key 8B48AD6246925553
# gpg -a --export 8B48AD6246925553 | sudo apt-key add -
# gpg --keyserver pgpkeys.mit.edu --recv-key 7638D0442B90D010
# gpg -a --export 7638D0442B90D010 | sudo apt-key add -
# gpg --keyserver pgpkeys.mit.edu --recv-key CBF8D6FD518E17E1
# gpg -a --export CBF8D6FD518E17E1 | sudo apt-key add -
# sudo apt-get update
# sudo apt-get install coturn=4.2.1.2-1 -y
# sudo cp -f ./turnserver.conf /etc/
# sudo cp -f ./turnuserdb.conf /etc/
# sudo cp -f ./coturn /etc/default
# sudo service coturn start

# ============  WebRTC installed ==========

echo "QEWD / Node.js middle tier is now installed"

echo "-----------------------------------------------------------------------"
echo " Installing Redis..."
echo "-----------------------------------------------------------------------"

cd ~
wget http://download.redis.io/redis-stable.tar.gz
tar xvzf redis-stable.tar.gz

# rename the created redis directory to just redis

mv redis-stable redis
cd redis

# build Redis

echo "Building Redis - be patient, this will take a few minutes"

make
sudo make install
cd utils

PORT=6379
CONFIG_FILE=/etc/redis/6379.conf
LOG_FILE=/var/log/redis_6379.log
DATA_DIR=/var/lib/redis/6379
EXECUTABLE=/usr/local/bin/redis-server

echo -e "${PORT}\n${CONFIG_FILE}\n${LOG_FILE}\n${DATA_DIR}\n${EXECUTABLE}\n" | sudo ./install_server.sh
sudo update-rc.d redis_6379 defaults

echo "Redis is now installed and running, listening on port 6379"

cd ~/qewd

echo "-----------------------------------------------------------------------"
echo " Installing MySQL Server..."
echo "-----------------------------------------------------------------------"

# Set default MySQL password to get rid of the prompt during install
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password password'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password password'

# Install MySQL packages
sudo apt-get install -y mysql-server
sudo service mysql start

# Run the database scripts

cd ~
mysql -u root -ppassword < ~/qewd/node_modules/qewd-ripple/data/create_database_and_tables.sql
mysql -u root -ppassword < ~/qewd/node_modules/qewd-ripple/data/populate_general_practitioners_table.sql
mysql -u root -ppassword < ~/qewd/node_modules/qewd-ripple/data/populate_medical_departments_table.sql
mysql -u root -ppassword < ~/qewd/node_modules/qewd-ripple/data/populate_patients_table.sql

echo "-----------------------------------------------------------------------"
echo " MySQL environment and data set up"
echo "-----------------------------------------------------------------------"


echo "-----------------------------------------------------------------------"
echo " Initialising deployment environment..."
echo "-----------------------------------------------------------------------"

# Retrieve the UI code
cd ~

# wget -O ripple_ui.zip https://github.com/PulseTile/PulseTile/blob/develop/build/PulseTile-latest.zip?raw=true

wget -O ripple_ui.zip https://github.com/PulseTile/PulseTile/blob/master/build/PulseTile-latest.zip?raw=true 

# Unpack the UI

unzip ripple_ui.zip

# move it into place

mv -v ~/dist/* ~/qewd/www/

# Install Swagger UI and specification

echo "-----------------------------------------------------------------------"
echo " Installing Swagger UI & Specification for Ripple"
echo "-----------------------------------------------------------------------"

cd ~/qewd/www
mkdir swagger
git clone https://github.com/swagger-api/swagger-ui.git
cp ~/qewd/node_modules/qewd-ripple/swagger/index.html ~/qewd/www/swagger-ui/dist
cp ~/qewd/node_modules/qewd-ripple/swagger/*.json ~/qewd/www/swagger
cp ~/qewd/node_modules/qewd-ripple/swagger/createSwaggerSpec.js ~/qewd


# Map port 80 to port 3000
# sudo iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j REDIRECT --to-port 3000

# echo "----------------------------------------------------------------------------------"
# echo " Port 80 will be permanently mapped to port 3000"
# echo "  Answer Yes to all questions that follow to make this happen...                  "
# echo "----------------------------------------------------------------------------------"

# sudo apt-get install iptables-persistent

# ========== Install nginx Proxy, listening on port 80 =================

#  alias /var/www to the QEWD www directory

sudo ln -s ~/qewd/www/ /var/www
sudo ln -s ~/qewd/ssl/ /var/ssl
sudo apt-get install -y nginx
sudo cp ~/qewd/node_modules/qewd-ripple/nginx/sites-available/default /etc/nginx/sites-available/default
sudo systemctl restart nginx

cd ~/qewd
pm2 start ripple-demo.js
pm2 start ripple-secure.js

echo "----------------------------------------------------------------------------------"
echo " The set up of the QEWD Ripple Middle Tier on your Ubuntu server is now complete! "
echo "  Startup template files (ripple-demo.js and ripple-secure.js                     "
echo "    are in the ~/qewd directory.  Add the appropriate Auth0 credentials           "
echo "                                                                                  "
echo "  ripple-demo and ripple-secure have been started in PM2 for you                  "
echo "----------------------------------------------------------------------------------"

