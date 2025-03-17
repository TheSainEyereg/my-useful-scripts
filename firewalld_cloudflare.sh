#!/usr/bin/env bash
set -e

if [ "$EUID" -ne 0 ]; then
	echo -e "\033[0;31mPlease run this script as root\033[0m"
	{
		return 1 &> /dev/null
	} || {
		exit 1
	}
fi

echo "Downloading Cloudflare IPs..."
curl -L https://www.cloudflare.com/ips-v4 > .ips-v4
curl -L https://www.cloudflare.com/ips-v6 > .ips-v6

if firewall-cmd --get-zones | grep -q '\bcloudflare\b'; then
	echo "Cloudflare zone already exists, deleting..."
    firewall-cmd --delete-zone=cloudflare --permanent
    firewall-cmd --reload
fi

echo "Creating Cloudflare zone..."
firewall-cmd --new-zone=cloudflare --permanent
firewall-cmd --reload

echo "Adding IPv4 IPs..."
for i in $(<.ips-v4); do
    firewall-cmd --zone=cloudflare --add-source="$i" --permanent
done

echo "Adding IPv6 IPs..."
for i in $(<.ips-v6); do
    firewall-cmd --zone=cloudflare --add-source="$i" --permanent
done

echo "Adding ports..."
firewall-cmd --zone=cloudflare --add-port=80/tcp --permanent
firewall-cmd --zone=cloudflare --add-port=443/tcp --permanent

echo "Reloading firewall..."
firewall-cmd --reload

echo "Done."