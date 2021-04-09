#!/bin/bash

rm -rf /etc/webconfs/apache
rm -rf /var/web
rm -rf /etc/postfix-conf 
ln -s /shared-mount/apache-web-config/ /etc/webconfs/apache
ln -s /shared-mount/web/ /var/web
ln -s /shared-mount/postfix-conf /etc/postfix-conf
touch /etc/webconfs/apache/blank.conf

service syslog-ng start &
status=$?
if [ $status -ne 0 ]; then
    echo "Failed to start syslog-ng: $status"
    exit $status
fi



# Start the first process
env > /etc/.cronenv
rm /etc/cron.d/dockercron
ln -s /shared-mount/postfix-conf/dockercron /etc/cron.d/dockercron

service cron start &
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start cron: $status"
  exit $status
fi

# Start the second process
cp /shared-mount/postfix-conf/sasl_passwd /etc/postfix/sasl/
cp /shared-mount/postfix-conf/main.cf /etc/postfix/
echo container > /etc/mailname
postmap /etc/postfix/sasl/sasl_passwd

service postfix start &
status=$?
if [ $status -ne 0 ]; then
	  echo "Failed to start postfix: $status"
    exit $status
fi

# Start the second process
service apache2 start &
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start apache2: $status"
  exit $status
fi
bash
