#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root. Please run with 'sudo'."
  exit 1
fi

# Get the actual user who ran sudo
REAL_USER=$(logname || who am i | awk '{print $1}')
REAL_HOME=$(eval echo ~$REAL_USER)

# Step 1: Install required packages
echo "Installing required packages: zsh, fzf, curl, git, nano..."
apt update && apt install -y zsh fzf curl git nano

# Step 2: Install Oh My Zsh for the real user
echo "Installing Oh My Zsh..."
sudo -u $REAL_USER sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

mkdir -p ${REAL_HOME}/.oh-my-zsh/custom/plugins/

# Step 3: Clone necessary plugins
echo "Cloning ZSH plugins..."
git clone https://github.com/zsh-users/zsh-autosuggestions ${REAL_HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${REAL_HOME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-history-substring-search ${REAL_HOME}/.oh-my-zsh/custom/plugins/zsh-history-substring-search
git clone https://github.com/zsh-users/zsh-completions ${REAL_HOME}/.oh-my-zsh/custom/plugins/zsh-completions
git clone https://github.com/psprint/zsh-navigation-tools ${REAL_HOME}/.oh-my-zsh/custom/plugins/zsh-navigation-tools

# Ensure ownership of .oh-my-zsh
chown -R $REAL_USER:$REAL_USER "${REAL_HOME}/.oh-my-zsh"

# Step 4: Change default shell to zsh for the real user
chsh -s $(which zsh) $REAL_USER

# Step 5: Configure .zshrc file
echo "Configuring .zshrc file..."

# Remove the existing .zshrc if it exists
if [ -f "${REAL_HOME}/.zshrc" ]; then
  echo "Backing up existing .zshrc..."
  sudo -u $REAL_USER mv "${REAL_HOME}/.zshrc" "${REAL_HOME}/.zshrc.backup"
fi

# Download the new .zshrc file
CONFIG_URL="https://raw.githubusercontent.com/HenryHendersonDev/personal-setup-scripts-1/refs/heads/main/backups/.zshrc"

if command -v wget &>/dev/null; then
  sudo -u $REAL_USER wget -O "${REAL_HOME}/.zshrc" $CONFIG_URL
elif command -v curl &>/dev/null; then
  sudo -u $REAL_USER curl -o "${REAL_HOME}/.zshrc" $CONFIG_URL
else
  echo "Neither wget nor curl is available. Please install one of them and try again."
  exit 1
fi

# Ensure proper ownership of the new .zshrc
chown $REAL_USER:$REAL_USER "${REAL_HOME}/.zshrc"

# Inform the user about the backup script
echo -e "\nIf you encounter any issues with missing ZSH plugins, navigate to your Downloads folder and run the script: ZSH-plugins.sh"
echo -e "This will reattempt to set up the plugins.\n"

echo "ZSH setup complete. Please restart your terminal."
