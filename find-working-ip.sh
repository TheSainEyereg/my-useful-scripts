#!/usr/bin/env bash

set -eou pipefail

DIG_ADDITIONS="+https @dns.google"

if ! command -v dig >/dev/null 2>&1; then
    echo "dig is not installed."
    exit 1
fi

if [ -z "$1" ]; then
    echo "Usage: $0 <domain>"
    exit 1
fi

domain="${1#*//}"
domain="${domain%%/*}"
echo "Using domain: $domain"

dig +short $DIG_ADDITIONS $domain | while read ip; do

    echo -n "Trying $ip... "
    
    curl -sS -m 3 --connect-to ::$ip https://$domain/ -o/dev/null \
        && echo "WORKING"
done