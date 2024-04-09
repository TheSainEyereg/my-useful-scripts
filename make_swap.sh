#!/usr/bin/env bash

if [ "$EUID" -ne 0 ]; then
	echo -e "\033[0;31mPlease run this script as root\033[0m"
	{
		return 1 &> /dev/null
	} || {
		exit 1
	}
fi


echo -n "Enter swap file size in fallocate format: "
read size
if [ -z "$size" ]; then
	echo -e "\033[0;31mNo size specified\033[0m"
	{
		return 1 &> /dev/null
	} || {
		exit 1
	}
fi

sudo fallocate -l $size /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
sudo echo "/swapfile swap swap defaults 0 0" >> /etc/fstab

echo "Swap file created and added to /etc/fstab"