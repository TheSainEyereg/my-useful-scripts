#!/usr/bin/env bash

if [ "$EUID" -ne 0 ]; then
	echo -e "\033[0;31mPlease run this script as root\033[0m"
	{
		return 1 &> /dev/null
	} || {
		exit 1
	}
fi

for ipt in iptables iptables-legacy ip6tables ip6tables-legacy; do
	{
		$ipt --flush
		$ipt --flush -t nat
		$ipt --delete-chain
		$ipt --delete-chain -t nat
		$ipt -P FORWARD ACCEPT
		$ipt -P INPUT ACCEPT
		$ipt -P OUTPUT ACCEPT

		echo "$ipt cleared"
	} || {
		echo "$ipt not found"
	}
done
