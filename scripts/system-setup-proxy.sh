#!/bin/bash

# Define color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Error handling function
handle_error() {
    echo -e "${RED}Error: $1${NC}"
    exit 1
}

# Success message function
success_msg() {
    echo -e "${GREEN}$1${NC}"
}

# Info message function
info_msg() {
    echo -e "${BLUE}$1${NC}"
}

# Warning message function
warning_msg() {
    echo -e "${YELLOW}$1${NC}"
}

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
    handle_error "This script must be run as root. Please run with 'sudo'."
fi

# Get the actual user who invoked sudo
ACTUAL_USER=$(logname || who am i | awk '{print $1}')
ACTUAL_HOME=$(eval echo ~${ACTUAL_USER})

# Create temp directory in Downloads first
info_msg "_________CREATE TEMP DIRECTORY_________"
TEMP_DIR="${ACTUAL_HOME}/Downloads/temp"
mkdir -p "$TEMP_DIR" || handle_error "Failed to create temp directory"
chown -R "${ACTUAL_USER}:${ACTUAL_USER}" "$TEMP_DIR"

# Create scripts directory
SCRIPTS_DIR="${ACTUAL_HOME}/Downloads/scripts"
mkdir -p "$SCRIPTS_DIR" || handle_error "Failed to create scripts directory"
chown -R "${ACTUAL_USER}:${ACTUAL_USER}" "$SCRIPTS_DIR"

# Backup important files
backup_dir="${ACTUAL_HOME}/setup_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$backup_dir" || handle_error "Failed to create backup directory"
chown -R "${ACTUAL_USER}:${ACTUAL_USER}" "$backup_dir"

TEXT_COLOR_GREEN='\033[0;32m'
TEXT_COLOR_RESET='\033[0m'

DISPLAY_TEXT="The Extensions are successfully installed but you ain't gonna see them once restarted it will appear and automatically updating to latest version after that it will tell you to logout and login then extension will fine. if it's not showing right now dont; worry"

BOX_WIDTH=100
BOX_BORDER=$(printf '_%.0s' $(seq 1 $BOX_WIDTH))

echo -e "${TEXT_COLOR_GREEN}${BOX_BORDER}${TEXT_COLOR_RESET}"
echo -e "${TEXT_COLOR_GREEN}|| ${DISPLAY_TEXT:0:$(($BOX_WIDTH - 4))} ||${TEXT_COLOR_RESET}"
echo -e "${TEXT_COLOR_GREEN}${BOX_BORDER}${TEXT_COLOR_RESET}"

# Update and Upgrade the System
info_msg "_________UPDATE AND UPGRADE SYSTEM_________"
apt update || handle_error "Failed to update package lists"
apt install nala -y || handle_error "Failed to download NALA"

# Install Nvidia drivers
info_msg "_________INSTALL REQUIRED DEPENDENCIES_________"
nala install -y nvidia-driver || handle_error "Failed to install nvidia-drivers"
sudo -u "$ACTUAL_USER" curl --socks5 127.0.0.1:10808 -o /var/lib/gdm3/.config/monitors.xml https://raw.githubusercontent.com/HenryHendersonDev/personal-setup-scripts-1/refs/heads/main/backups/monitors.xml
sudo -u "$ACTUAL_USER" curl --socks5 127.0.0.1:10808 -o "${ACTUAL_HOME}/.config/monitors.xml" https://raw.githubusercontent.com/HenryHendersonDev/personal-setup-scripts-1/refs/heads/main/backups/monitors.xml


# Install required dependencies first
info_msg "_________INSTALL REQUIRED DEPENDENCIES_________"
nala install -y dbus dbus-x11 || handle_error "Failed to install dbus dependencies"

# Update and Upgrade the System
info_msg "_________UPDATE AND UPGRADE SYSTEM_________"
nala update || handle_error "Failed to update package lists"
nala upgrade -y || handle_error "Failed to upgrade packages"

# Install Flatpak and dependencies
info_msg "_________INSTALL FLATPAK AND DEPENDENCIES_________"
nala install -y flatpak gnome-software-plugin-flatpak || handle_error "Failed to install Flatpak"
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Install Gnome Extensions and Tweaks Packages
info_msg "_________INSTALL GNOME EXTENSIONS AND TWEAKS_________"
nala install -y gnome-shell-extensions gnome-tweaks gnome-shell-extension-manager || handle_error "Failed to install GNOME packages"

# Download and install extensions
info_msg "_________DOWNLOADING AND INSTALLING GNOME EXTENSIONS_________"
# Download as the actual user
sudo -u "$ACTUAL_USER"  -P "$TEMP_DIR" https://raw.githubusercontent.com/HenryHendersonDev/personal-setup-scripts-1/main/assets/extension.zip || handle_error "Failed to download extensions"

# Create extensions directory and set permissions
mkdir -p "$TEMP_DIR/extensions"
chown "${ACTUAL_USER}:${ACTUAL_USER}" "$TEMP_DIR/extensions"

# Unzip as the actual user
sudo -u "$ACTUAL_USER" unzip -o "$TEMP_DIR/extension.zip" -d "$TEMP_DIR/extensions" || handle_error "Failed to unzip extensions"

# Set proper permissions
chmod -R 755 "$TEMP_DIR/extensions"
chown -R "${ACTUAL_USER}:${ACTUAL_USER}" "$TEMP_DIR/extensions"

# Install and enable extensions as the actual user
cd "$TEMP_DIR/extensions" || handle_error "Failed to access extensions directory"
for ext in *.shell-extension.zip; do
    if [ -f "$ext" ]; then
        sudo -u "$ACTUAL_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u $ACTUAL_USER)/bus" gnome-extensions install --force "$ext" || warning_msg "Failed to install extension: $ext"
    fi
done

# Enable extensions with proper dbus session
sudo -u "$ACTUAL_USER" bash -c "export DBUS_SESSION_BUS_ADDRESS=\"unix:path=/run/user/$(id -u $ACTUAL_USER)/bus\" && {
    gnome-extensions enable just-perfection-desktop@just-perfection
    gnome-extensions enable compiz-windows-effect@hermes83.github.com
    gnome-extensions enable blur-my-shell@aunetx
    gnome-extensions enable dash-to-dock@micxgx.gmail.com
    gnome-extensions enable Vitals@CoreCoding.com
    gnome-extensions enable compiz-alike-magic-lamp-effect@hermes83.github.com
    gnome-extensions enable clipboard-indicator@tudmotu.com
}"

# Download backup files with error checking
info_msg "_________DOWNLOAD BACKUP FILES_________"
sudo -u "$ACTUAL_USER"  -P "$TEMP_DIR" https://raw.githubusercontent.com/HenryHendersonDev/personal-setup-scripts-1/main/backups/gnome-backup.txt || handle_error "Failed to download gnome-backup.txt"
sudo -u "$ACTUAL_USER" curl --socks5 127.0.0.1:10808 -o "$TEMP_DIR/gnome-extensions-backup.txt" https://raw.githubusercontent.com/HenryHendersonDev/personal-setup-scripts-1/main/backups/gnome-extensions-backup.txt || handle_error "Failed to download gnome-extensions-backup.txt"


# Restore settings from backups with proper dbus session
info_msg "_________RESTORE SETTINGS FROM BACKUPS_________"
sudo -u "$ACTUAL_USER" bash -c "export DBUS_SESSION_BUS_ADDRESS=\"unix:path=/run/user/$(id -u $ACTUAL_USER)/bus\" && {
    if [ -f \"$TEMP_DIR/gnome-backup.txt\" ]; then
        dconf load /org/gnome/ < \"$TEMP_DIR/gnome-backup.txt\"
    fi
    if [ -f \"$TEMP_DIR/gnome-extensions-backup.txt\" ]; then
        dconf load /org/gnome/shell/extensions/ < \"$TEMP_DIR/gnome-extensions-backup.txt\"
    fi
}"

# List GNOME extensions
info_msg "_________LIST GNOME EXTENSIONS_________"
sudo -u "$ACTUAL_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u $ACTUAL_USER)/bus" gnome-extensions list

# Add sources
info_msg "_________ADD SOURCES TO APT_________"
echo "deb http://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware" | tee -a /etc/apt/sources.list
nala update || warning_msg "Failed to update after adding sources"

# Fix Network issues (if requested)
info_msg "_________NETWORK MANAGER SETUP_________"
if [ -f /etc/NetworkManager/NetworkManager.conf ]; then
    sed -i 's/^\(managed=\)false/\1true/' /etc/NetworkManager/NetworkManager.conf
    systemctl restart NetworkManager
    nmcli device status
fi

# Remove and reinstall packages
info_msg "_________PACKAGE MANAGEMENT_________"
nala remove --purge gnome-calculator gnome-characters gnome-contacts gnome-software totem gnome-system-monitor firefox-esr -y || warning_msg "Some packages couldn't be removed"
nala install -y nautilus gnome-calculator gnome-system-monitor || warning_msg "Failed to install some packages"

# Install utilities
info_msg "_________INSTALL UTILITIES_________"
nala install -y wget curl neofetch postgresql postgresql-contrib git preload imwheel || warning_msg "Failed to install some utilities"
systemctl start postgresql || warning_msg "PostgreSQL service failed to start"
systemctl enable postgresql
sudo systemctl enable preload

# Install Warp
info_msg "_________INSTALL WARP_________"
sudo -u "$ACTUAL_USER" curl --socks5 127.0.0.1:10808 -o "${TEMP_DIR}/warp.deb" https://app.warp.dev/download?package=deb || handle_error "Failed to download Warp"

dpkg -i "${TEMP_DIR}/warp.deb" || nala --fix-broken install -y

# Install Apps using Flatpak
info_msg "_________INSTALL FLATPAK APPS_________"
flatpak_apps=(
    "com.redis.RedisInsight"
    "md.obsidian.Obsidian"
    "org.telegram.desktop"
    "com.usebruno.Bruno"
    "org.bleachbit.BleachBit"
)

for app in "${flatpak_apps[@]}"; do
    flatpak install flathub "$app" -y || warning_msg "Failed to install $app"
done

# Install Brave Browser
info_msg "_________INSTALL BRAVE BROWSER_________"
if ! [ -f /usr/share/keyrings/brave-browser-archive-keyring.gpg ]; then
    curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | tee /etc/apt/sources.list.d/brave-browser-release.list
    nala update || warning_msg "Failed to update after adding Brave repository"
fi
nala install -y brave-browser || warning_msg "Failed to install Brave browser"

# Install VS Code
info_msg "_________INSTALL VS CODE_________"
if ! curl --socks5 127.0.0.1:10808 -o "${TEMP_DIR}/vscode.deb" "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"; then
    warning_msg "Failed to download VS Code"
else
    if ! dpkg -i "${TEMP_DIR}/vscode.deb"; then
        warning_msg "Failed to install VS Code"
        nala --fix-broken install -y
    fi
fi

# Install Chrome
info_msg "_________INSTALL CHROME_________"
curl --socks5 127.0.0.1:10808 -o "${TEMP_DIR}/chrome.deb" "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" || warning_msg "Failed to download Chrome"
dpkg -i "${TEMP_DIR}/chrome.deb" || nala --fix-broken install -y

# Install Redis
info_msg "_________INSTALL REDIS_________"
nala install -y redis-server || warning_msg "Failed to install Redis"
systemctl start redis-server || warning_msg "Redis service failed to start"
systemctl enable redis-server

# Install Mailhog
info_msg "_________INSTALL MAILHOG_________"
curl --socks5 127.0.0.1:10808 -o "${TEMP_DIR}/MailHog" "https://github.com/mailhog/MailHog/releases/download/v1.0.1/MailHog_linux_amd64" || warning_msg "Failed to download MailHog"
if [ -f "${TEMP_DIR}/MailHog" ]; then
    chmod +x "${TEMP_DIR}/MailHog"
    mv "${TEMP_DIR}/MailHog" /usr/local/bin/
fi

# Install fonts
info_msg "_________INSTALL FONT_________"
FONT_DIR="${ACTUAL_HOME}/.fonts"
mkdir -p "$FONT_DIR"
chown "${ACTUAL_USER}:${ACTUAL_USER}" "$FONT_DIR"

sudo -u "$ACTUAL_USER" curl --socks5 127.0.0.1:10808 -o "$TEMP_DIR/fonts.zip" "https://github.com/HenryHendersonDev/personal-setup-scripts-1/raw/main/assets/fonts.zip" || warning_msg "Failed to download fonts"
if [ -f "$TEMP_DIR/fonts.zip" ]; then
    sudo -u "$ACTUAL_USER" unzip -o "$TEMP_DIR/fonts.zip" -d "$TEMP_DIR/fonts"
    sudo -u "$ACTUAL_USER" mv "$TEMP_DIR"/fonts/*.ttf "$FONT_DIR/" 2>/dev/null || warning_msg "No fonts to move"
    fc-cache -f
fi

# Download wallpaper to Downloads
info_msg "_________DOWNLOAD WALLPAPER_________"
sudo -u "$ACTUAL_USER" curl --socks5 127.0.0.1:10808 -o "${ACTUAL_HOME}/Downloads/wallpaper.jpg" "https://raw.githubusercontent.com/HenryHendersonDev/personal-setup-scripts-1/main/assets/wallpaper.jpg" || warning_msg "Failed to download wallpaper"
success_msg "Wallpaper downloaded to Downloads folder. You can set it manually if desired."

# Download setup scripts
info_msg "_________DOWNLOADING SETUP SCRIPTS_________"
SCRIPT_URLS=(
    "https://raw.githubusercontent.com/HenryHendersonDev/personal-setup-scripts-1/main/scripts/setup-zsh-oh-my-zsh.sh"
    "https://raw.githubusercontent.com/HenryHendersonDev/personal-setup-scripts-1/main/scripts/setup-vless-xray.sh"
    "https://raw.githubusercontent.com/HenryHendersonDev/personal-setup-scripts-1/main/scripts/nvidia-display-setup.sh"
    "https://raw.githubusercontent.com/HenryHendersonDev/personal-setup-scripts-1/refs/heads/main/scripts/ZSH-plugins.sh"
)

for url in "${SCRIPT_URLS[@]}"; do
    filename=$(basename "$url")
    sudo -u "$ACTUAL_USER" curl --socks5 127.0.0.1:10808 -o "$SCRIPTS_DIR/$filename" "$url" || warning_msg "Failed to download $filename"
    chmod +x "$SCRIPTS_DIR/$filename"
done


success_msg "NVIDIA display setup script has been downloaded to Downloads/scripts folder. Run it later if you have any issues with NVIDIA resolution not showing 1280x1024."

# Fix Scroll Issue
cat >"${ACTUAL_HOME}/.imwheelrc" <<EOF
".*"
None,      Up,   Button4, 1
None,      Down, Button5, 1
EOF

imwheel
echo 'imwheel' >>"${ACTUAL_HOME}/.xinitrc"

# Clean up the temp directory
info_msg "_________CLEAN UP_________"
rm -rf "$TEMP_DIR"

# Final system cleanup
info_msg "_________FINAL SYSTEM CLEANUP_________"
nala autoremove -y
nala clean
sudo dpkg --configure -a
sudo apt remove imagemagick -y

# Ask about running setup-vless-xray.sh
read -p "Do you want to run setup-vless-xray.sh? (y/n): " run_vless
if [[ $run_vless == "y" ]]; then
    info_msg "Running setup-vless-xray.sh..."
    bash "$SCRIPTS_DIR/setup-vless-xray.sh"
fi

# Ask about running setup-zsh-oh-my-zsh.sh
read -p "Do you want to run setup-zsh-oh-my-zsh.sh? (y/n): " run_zsh
if [[ $run_zsh == "y" ]]; then
    info_msg "Running setup-zsh-oh-my-zsh.sh..."
    bash "$SCRIPTS_DIR/setup-zsh-oh-my-zsh.sh"
fi

# Verify services
info_msg "_________SERVICE STATUS CHECK_________"
systemctl status postgresql --no-pager || warning_msg "PostgreSQL service check failed"
systemctl status redis-server --no-pager || warning_msg "Redis service check failed"

# handling System Services On Startup Auto Run
info_msg "_________HANDLING SYSTEM SERVICES ON STARTUP_________"
sudo systemctl disable bluetooth.service
sudo systemctl disable console-getty.service
sudo systemctl disable debug-shell.service
sudo systemctl disable nftables.service
sudo systemctl disable pg_receivewal@.service
sudo systemctl disable postgresql.service
sudo systemctl disable redis-server@.service
sudo systemctl disable redis-server.service
sudo systemctl disable rtkit-daemon.service
sudo systemctl disable serial-getty@.service
sudo systemctl disable sysstat.service
sudo systemctl disable systemd-boot-check-no-failures.service
sudo systemctl disable systemd-sysext.service
sudo systemctl disable systemd-time-wait-sync.service
sudo systemctl disable upower.service
sudo systemctl disable wpa_supplicant-nl80211@.service
sudo systemctl disable wpa_supplicant-wired@.service
sudo systemctl disable bluetooth.service
sudo systemctl enable nvidia-hibernate.service
sudo systemctl enable nvidia-resume.service
sudo systemctl enable nvidia-suspend.service

# Print final success message
MESSAGE="Setup completed! Please reboot your system to apply all changes."

echo -e "\033[1m$MESSAGE\033[0m"
for i in {10..1}; do
    echo "Rebooting in $i seconds..."
    sleep 1
done
echo "Rebooting now..."
sudo reboot
