#!/usr/bin/env bash

PANEL_URL="https://panel.example.com"
API_KEY="YOUR_TOKEN" # Application API key with read access to allocations
NODE_ID=1

IGNORE_ALIAS=("ignore" "local") # array of ignored aliases
IGNORE_IP=("127.0.0.1") # array of ignored allocations

UPNP_DURATION=600 # 10 minutes

set -e

LOCAL_IP=$(ip route show | head -n 1 | awk '{print $9}')

res=$(curl -s "$PANEL_URL/api/application/nodes/$NODE_ID/allocations" \
	--request "GET" \
	--header "Accept: application/json" \
	--header "Authorization: Bearer $API_KEY")

function processRow() {
	ip=$1
	alias=$2
	assigned=$3
	port=$4
}

jq -r ".data[].attributes | {ip, alias, assigned, port} | map(.) | @sh" <<< "$res" | while read row; do
	eval processRow $row

	if [[ " ${IGNORE_ALIAS[@]} " =~ " ${alias} " ]]; then
		continue
	fi

	if [[ " ${IGNORE_IP[@]} " =~ " ${ip} " ]]; then
		continue
	fi

	if [[ $assigned == "true" ]]; then
		label="$ip:$port ($alias)"
		echo "$label is assigned"

		first_word=$(awk '{print $1}' <<< "$alias")
		if [[ "$first_word" == "TCP" || "$first_word" == "UDP" ]]; then
			proto_array=("$first_word")
		else
			proto_array=("TCP" "UDP")
		fi

		for proto in "${proto_array[@]}"; do
			upnpc -e "[ptero-upnp] $proto $label" -a $LOCAL_IP $port $port $proto $UPNP_DURATION | tail -n 1
		done
	fi
done
