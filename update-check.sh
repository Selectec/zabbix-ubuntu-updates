#!/bin/bash
### Make sure zabbix-sender package is installed ###
### Adapted from https://github.com/Open-Future-Belgium/zabbix/tree/master/check-yum-updates ###

### Set Some Variables ###
ZBX_DATA=/tmp/zabbix-sender-apt.data
HOSTNAME=$(egrep ^Hostname= /etc/zabbix/zabbix_agentd.conf | cut -d = -f 2)
ZBX_SERVER_IP=$(egrep ^ServerActive /etc/zabbix/zabbix_agentd.conf | cut -d = -f 2)
UPDATES=$(/usr/lib/update-notifier/apt-check 2>&1)

SEC=0
NON_SEC=0

### Check if Zabbix-Sender is Installed ###
ZSEND=$(dpkg-query -l | grep zabbix-sender | wc -l)
if [ $ZSEND != "1" ]
then
  echo "Zabbix-Sender NOT installed"
  echo "Run: sudo apt install zabbix-sender"
  exit 1;
fi

### Check for Updates ###
if [ $UPDATES = "0;0" ]
then
  TOTAL=0
fi

### Security updates
PENDING=$(echo "$UPDATES" | cut -d ";" -f 2)
if [ "$PENDING" != "0" ]
then
  TOTAL=$(($TOTAL + $PENDING))
  SEC=$PENDING
fi

### Non Security updates
PENDING=$(echo "$UPDATES" | cut -d ";" -f 1)
if [ "$PENDING" != "0" ]
then
  TOTAL=$(($TOTAL + $PENDING))
  NON_SEC=$PENDING
fi

### Add data to file and send it to Zabbix Server ###
echo -n > $ZBX_DATA
echo "$HOSTNAME apt.security $SEC" >> $ZBX_DATA
echo "$HOSTNAME apt.non-security $NON_SEC" >> $ZBX_DATA
echo "$HOSTNAME apt.total-updates $TOTAL" >> $ZBX_DATA

### Drop anything after $ZBX_DATA if not using TLS
zabbix_sender -z $ZBX_SERVER_IP -i $ZBX_DATA --tls-connect psk --tls-psk-identity "PSK 001" --tls-psk-file /etc/zabbix/zabbix_agentd.psk
