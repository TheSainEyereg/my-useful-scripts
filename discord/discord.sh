#!/usr/bin/env bash
set -e

DISCORD_BRANCH="canary" # "stable", "canary", "ptb"
DISCORD_PATH="/opt/discord-canary"
DISCORD_PROCESS="DiscordCanary"

UPDATE_COMMAND="yay -S --noconfirm discord-canary"

say_error() {
        echo -e "\033[0;31m$1\033[0m"
}

kill_discord() {
		echo "Killing $DISCORD_PROCESS"
		pkill -9 -f "$DISCORD_PROCESS$" || true
}

if [ "$EUID" -eq 0 ]; then
        say_error "Do not run this install script as root"
        exit 1
fi

REMOTE=$(curl -s "https://discord.com/api/updates/$DISCORD_BRANCH?platform=linux" | jq -r .name)
LOCAL=$(cat "$DISCORD_PATH/resources/build_info.json" | jq -r .version)

if [ "$REMOTE" = "$LOCAL" ]; then
	echo "Discord is already up to date"
	kstart "$DISCORD_PATH/$DISCORD_PROCESS"
	exit 0
fi

echo "New version available: $REMOTE (current: $LOCAL)"

kill_discord
echo "Running update command"
$UPDATE_COMMAND > /dev/null

NEW=$(cat "$DISCORD_PATH/resources/build_info.json" | jq -r .version)

if [ "$REMOTE" != "$NEW" ]; then
	say_error "Failed to update to $REMOTE, latest downloaded is $NEW"
	read -rsp $'Press any key to continue...\n' -n 1
	exit 0
fi

if [ -f "$(dirname "$0")/vencord.sh" ]; then
	echo "Intalling Vencord"

	"$DISCORD_PATH/$DISCORD_PROCESS" 2> /dev/null | while read -r line; do
		if [[ $line == *"status: 'launching'"* ]]; then
			kill_discord
			break
		fi
	done
	"$(dirname "$0")/vencord.sh" -branch $DISCORD_BRANCH -install-openasar -install
else
	echo "Skipping Vencord install as vencord.sh not found"
fi

kstart "$DISCORD_PATH/$DISCORD_PROCESS"