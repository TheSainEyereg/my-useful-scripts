#!/usr/bin/env bash
set -e

say_error() {
	echo -e "\033[0;31m$1\033[0m"
}

if [ "$EUID" -eq 0 ]; then
	say_error "Do not run this install script as root"
	exit 1
fi

outfile=$(mktemp)
trap 'rm -f "$outfile"' EXIT

echo "Downloading Vencord installer"

curl -sS https://github.com/Vendicated/VencordInstaller/releases/latest/download/VencordInstallerCli-Linux \
	--output "$outfile" \
	--location

chmod +x "$outfile"

if command -v sudo >/dev/null; then
	echo "Running with sudo"
	sudo "$outfile" "$@"
elif command -v doas >/dev/null; then
	echo "Running with doas"
	doas "$outfile" "$@"
else
	say_error "No sudo or doas found"
fi