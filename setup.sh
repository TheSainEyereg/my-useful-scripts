#!/usr/bin/env bash

# Check if running as root
if [ ! "$EUID" -ne 0 ]; then
	echo -e "\033[0;31mPlease run this script as regular user\033[0m"
	{
		return 1 &> /dev/null
	} || {
		exit 1
	}
fi

# Run from scripts directory
base=$(basename "$0" 2> /dev/null)
dir=$(dirname "$0" 2> /dev/null)

if [[ -z $dir || -z $base || $base != *.sh ]]; then
	echo -e "\033[0;31mYou've sourced this script or renamed it without the .sh extension\033[0m"
	{
		return 1 &> /dev/null
	} || {
		exit 1
	}
fi
cd $dir

# Package manager update
echo "Updating packages..."
sudo apt update && sudo apt upgrade -y

# My common used packages
echo "Installing useful packages..."
sudo apt install nano vim cron curl wget git htop exa iftop nmap gh zip neofetch gcc g++ zsh -y

# Zsh & theme configs
echo "Installing zsh config..."
cp "configs/.zshrc" "$HOME"
cp "configs/.p10k.zsh" "$HOME"
sudo chsh -s $(which zsh) $(whoami)

# zgen
if [ ! -f "$HOME/.zgen" ]; then
	echo "Installing zgen..."
	git clone https://github.com/tarjoilija/zgen.git "$HOME/.zgen" &>/dev/null
fi

# Wakatime
if [ ! -f "$HOME/.wakatime.cfg" ]; then
	echo -n "Enter your wakatime key (leave empty if you dont have it): "
	read wakatimeKey
	if [ ! -z "$wakatimeKey" ]; then
		echo "Installing wakatime..."
		python3 -c "$(wget -q -O - https://raw.githubusercontent.com/wakatime/vim-wakatime/master/scripts/install_cli.py)" &>/dev/null
		echo "$wakatimeKey" >"$HOME/.wakatime.cfg"
	fi
fi

# NVM + nodejs
if [ ! -f "$NVM_DIR/nvm.sh" ]; then
	echo "Installing nvm and nodejs..."
	curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash &>/dev/null
	export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
	[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

	nvm install --lts &>/dev/null
	nvm alias default node &>/dev/null
	nvm use default &>/dev/null
fi

# Ask about swap file
if [ ! -f "/swapfile" ]; then
	read -p "Do you want to create a swap file? (y/n) " -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		chmod +x make_swap.sh
		sudo ./make_swap.sh
	fi
fi

# Ask if run clear_iptables.sh
if [ ! -f "/root/clear_iptables.sh" ]; then
	read -p "Do you want to run clear_iptables.sh and add it to crontab? (y/n) " -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		echo "Clearing iptables and adding reboot task to crontab..."
		chmod +x clear_iptables.sh
		sudo cp clear_iptables.sh /root
		sudo /root/clear_iptables.sh
		(
			sudo crontab -l 2>/dev/null
			echo "@reboot /root/clear_iptables.sh"
		) | sudo crontab -
	fi
fi

zsh
exit
