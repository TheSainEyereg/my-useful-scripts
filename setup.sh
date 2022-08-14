#!/usr/bin/env bash

# Package manager update
echo "Updating packages..." 
sudo apt update
sudo apt upgrade -y

# My common used packages 
echo "Installing useful packages..."
sudo apt install git wget curl htop iftop nmap gh zip neofetch gcc g++ zsh -y


# Zsh & theme configs
echo "Installing zsh config..."
cp "configs/.zshrc" "${HOME}"
cp "configs/.p10k.zsh" "${HOME}"
sudo chsh -s $(which zsh) $(whoami)

# zgen
if [ ! -f "${HOME}/.zgen" ]
then
	echo "Installing zgen..."
	git clone https://github.com/tarjoilija/zgen.git "${HOME}/.zgen" &> /dev/null
fi


# Wakatime
if [ ! -f "${HOME}/.wakatime.cfg" ]
then
	echo -n "Enter your wakatime key (leave empty if you dont have it): "
	read wakatimeKey
	if [ ! -z "$wakatimeKey" ]
	then
		echo "Installing wakatime..."
		python3 -c "$(wget -q -O - https://raw.githubusercontent.com/wakatime/vim-wakatime/master/scripts/install_cli.py)" &> /dev/null
		echo "$wakatimeKey" > "${HOME}/.wakatime.cfg"
	fi
fi


# NVM + nodejs
if [ ! -f "$NVM_DIR/nvm.sh" ]
then
	echo "Installing nvm and nodejs..."
	curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash &> /dev/null
	export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
	[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

	nvm install --latest-npm &> /dev/null
	nvm alias default node &> /dev/null
	nvm use default &> /dev/null
fi


# exa
if ! command -v exa &> /dev/null
then
	echo "Installing exa..."
	{ # try
		sudo apt install exa -y
	} || { # catch
		curl https://sh.rustup.rs -sSf | sh
		cargo install exa
	}
fi


# iptables for Oracle
if command -v iptables &> /dev/null
then
	echo "Installing UNSECURE iptables rules..."
	sudo cp "configs/rules.v4" "/etc/iptables/"
	sudo systemctl restart iptables
fi


zsh
exit