#!/bin/bash
# $1 = Azure storage account name
# $2 = Azure storage account key
# $3 = Azure file share name

echo "----BOOTSTRAP-START-----"

# install packages
apt-get -y install nginx cifs-utils

# enable services
systemctl start nginx
systemctl enable nginx

# mount file share
mkdir /mnt/$3
mount -t cifs //$1.file.core.windows.net/$3 /mnt/$3 -o vers=3.0,username=$1,password=$2,dir_mode=0755,file_mode=0664
echo "//$1.file.core.windows.net/$3 $4 cifs vers=3.0,username=$1,password=$2,dir_mode=0755,file_mode=0664,serverino" >> /etc/fstab

# create marker files for testing
echo "Connection: $(hostname) - $(hostname --ip-address)" > /mnt/$3/$(hostname).txt
echo "<h1>$(hostname)</h1>" > /var/www/html/index.html

echo "----BOOTSTRAP-END-----"


