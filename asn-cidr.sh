#!/usr/bin/env bash

set -euo pipefail

asn=${1:-}
ip=${2:-64}

if [[ -z "$asn" ]] || ! [[ "$ip" =~ ^(4|6|64)$ ]]; then
	echo "Usage: $0 <asn> [4|6|64]"
	exit 1
fi

# grep_arg=""
# if [ "$ip" = "4" ]; then
# 	grep_arg="route:"
# elif [ "$ip" = "6" ]; then
# 	grep_arg="route6:"
# else
# 	grep_arg="route:|route6:"
# fi

# echo "-i origin $asn" | nc whois.radb.net 43 | grep -E $grep_arg | awk '{print $2}'

jq_arg=""
if [ "$ip" = "4" ]; then
	jq_arg=".routes.v4"
elif [ "$ip" = "6" ]; then
	jq_arg=".routes.v6"
else
	jq_arg=".routes.v4 + .routes.v6"
fi

curl -sL "https://ip.guide/$asn" | jq -r "$jq_arg | .[]"
