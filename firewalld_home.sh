#!/usr/bin/env bash
set -e

SUBNET="192.168.0.0/16"

if [ "$EUID" -ne 0 ]; then
	echo -e "\033[0;31mPlease run this script as root\033[0m"
	{
		return 1 &> /dev/null
	} || {
		exit 1
	}
fi

echo "Clearing home zone..."
for service in $(firewall-cmd --zone=home --list-services); do
    firewall-cmd --zone=home --remove-service=$service --permanent
done

for port in $(firewall-cmd --zone=home --list-ports); do
    firewall-cmd --zone=home --remove-port=$port --permanent
done

for source in $(firewall-cmd --zone=home --list-sources); do
    firewall-cmd --zone=home --remove-source=$source --permanent
done

echo "Setting home zone target to ACCEPT..."
firewall-cmd --zone=home --set-target=ACCEPT --permanent

echo "Adding subnet to home zone..."
firewall-cmd --zone=home --add-source=$SUBNET --permanent

echo "Reloading firewall..."
firewall-cmd --reload

echo "Done."