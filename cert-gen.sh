#!/usr/bin/env bash

set -euo pipefail

usage() {
    echo "Usage:"
    echo "  $0 --key myCA.key --crt myCA.crt -d domain1.tld [-d domain2.tld]"
    exit 1
}

CA_KEY=""
CA_CRT=""
DOMAINS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --key|-k)
            CA_KEY="$2"
            shift 2
            ;;
        --crt|-c)
            CA_CRT="$2"
            shift 2
            ;;
        --domain|-d)
            DOMAINS+=("$2")
            shift 2
            ;;
        *)
            usage
            ;;
    esac
done

if [[ -z "$CA_KEY" || -z "$CA_CRT" || ${#DOMAINS[@]} -eq 0 ]]; then
    usage
fi

MAIN_DOMAIN="${DOMAINS[0]}"
OUT_DIR="$MAIN_DOMAIN"

mkdir -p "$OUT_DIR"

KEY_FILE="$OUT_DIR/$MAIN_DOMAIN.key"
CRT_FILE="$OUT_DIR/$MAIN_DOMAIN.crt"
CSR_FILE="$OUT_DIR/$MAIN_DOMAIN.csr"
CONF_FILE="$OUT_DIR/$MAIN_DOMAIN.cnf"


echo "Reading CA subject..."

CA_SUBJECT=$(openssl x509 \
    -noout \
    -subject \
    -nameopt compat \
    -in "$CA_CRT" \
    | sed 's/^subject=//')

echo "CA subject:"
echo "$CA_SUBJECT"

# Extract /FIELD=value parts safely
get_dn_field() {
    local field="$1"

    echo "$CA_SUBJECT" \
        | sed -n "s|.*\/$field=\([^/]*\).*|\1|p" \
        | sed "s/'/\\\\'/g"
}

C=$(get_dn_field C)
ST=$(get_dn_field ST)
L=$(get_dn_field L)
O=$(get_dn_field O)
OU=$(get_dn_field OU)

cat > "$CONF_FILE" <<EOF
[req]
default_bits = 4096
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[dn]
EOF

[[ -n "$C"  ]] && echo "C = $C"   >> "$CONF_FILE"
[[ -n "$ST" ]] && echo "ST = $ST" >> "$CONF_FILE"
[[ -n "$L"  ]] && echo "L = $L"   >> "$CONF_FILE"
[[ -n "$O"  ]] && echo "O = $O"   >> "$CONF_FILE"
[[ -n "$OU" ]] && echo "OU = $OU" >> "$CONF_FILE"

cat >> "$CONF_FILE" <<EOF
CN = $MAIN_DOMAIN

[req_ext]
subjectAltName = @alt_names

[alt_names]
EOF

INDEX=1
for DOMAIN in "${DOMAINS[@]}"; do
    echo "DNS.$INDEX = $DOMAIN" >> "$CONF_FILE"
    INDEX=$((INDEX + 1))
done


echo "Generating private key..."

openssl genrsa \
    -out "$KEY_FILE" \
    4096


echo "Generating CSR..."

openssl req \
    -new \
    -key "$KEY_FILE" \
    -out "$CSR_FILE" \
    -config "$CONF_FILE"


echo "Signing certificate..."

openssl x509 \
    -req \
    -in "$CSR_FILE" \
    -CA "$CA_CRT" \
    -CAkey "$CA_KEY" \
    -CAcreateserial \
    -out "$CRT_FILE" \
    -days 825 \
    -sha256 \
    -extensions req_ext \
    -extfile "$CONF_FILE"


rm "$CSR_FILE"
rm -f "${CA_CRT}.srl"


echo
echo "Generated:"
echo "  Certificate: $CRT_FILE"
echo "  Key:         $KEY_FILE"
