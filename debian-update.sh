#!/bin/bash

#################################
# Debian 12 Update Script.
#
# written by Sebastian Vencill
#
# https://github.com/large-farva/
#################################

# Define colors.
hex_color() {
    echo -e "\033[38;2;$(printf '%d;%d;%d' 0x${1:0:2} 0x${1:2:2} 0x${1:4:2})m"
}
RESET='\033[0m'
RED=$(hex_color "e06c75")
ORANGE=$(hex_color "d19a66")
GREEN=$(hex_color "98c379")
YELLOW=$(hex_color "e5c07b")
CYAN=$(hex_color "56b6c2")
WHITE=$(hex_color "f9f9f9")

# Print message function.
print_message() {
    COLOR=$1
    MESSAGE=$2
    echo -e "${COLOR}${MESSAGE}${RESET}"
}

# Log and print function.
log_and_print() {
    COLOR=$1
    MESSAGE=$2
    echo -e "${COLOR}${MESSAGE}${RESET}" | tee -a $LOG_FILE
}

# Log function.
log() {
    MESSAGE=$1
    echo -e "${MESSAGE}" >> $LOG_FILE
}

# Ensure the script is run with sudo
if [ "$EUID" -ne 0 ]; then
    print_message $ORANGE "This script needs to be run with sudo."
    exec sudo "$0" "$@"
fi

echo ""

# Define log directory and file.
# NOTE: ~/.logs/debian-update/ used as log directory.
SCRIPT_NAME=$(basename "$0" .sh)
LOG_DIR="$HOME/.logs/$SCRIPT_NAME"
DATE=$(date +'%Y-%m-%d_%H-%M-%S')
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$DATE.log"

# Create log directory (~/.logs/debian-update/)
mkdir -p $LOG_DIR

# Date / Time format.
CURRENT_DATE=$(date +'%m-%d-%Y')
CURRENT_TIME=$(date +'%H:%M:%S')

echo ""

# Function to get and display system information
print_system_info() {
    print_message $CYAN "SYSTEM INFORMATION"
    print_message $CYAN "===================="
    print_message $CYAN "OS: $(lsb_release -d | awk -F'\t' '{print $2}')"
    print_message $CYAN "Host: $(hostname)"
    print_message $CYAN "Kernel: $(uname -r)"
    print_message $CYAN "Uptime: $(uptime -p)"
    print_message $CYAN "Shell: $SHELL"
    print_message $CYAN "Packages: $(dpkg --get-selections | wc -l)"
    print_message $CYAN "===================="
    log "System Information: OS: $(lsb_release -d | awk -F'\t' '{print $2}'), Host: $(hostname), Kernel: $(uname -r), Uptime: $(uptime -p), Shell: $SHELL, Packages: $(dpkg --get-selections | wc -l)"
}

# Print system information
print_system_info

echo ""

# Check for internet.
print_message $YELLOW "Checking for internet connectivity..."
if ! ping -c 1 8.8.8.8 &> /dev/null; then
    print_message $RED "No internet connection. Exiting."
    log_and_print $RED "No internet connection. Exiting at $CURRENT_DATE $CURRENT_TIME."
    exit 1
else
    print_message $GREEN "Internet connection is available."
fi

echo ""

# Start update process.
log_and_print $WHITE "Starting update process on $CURRENT_DATE at $CURRENT_TIME"

echo ""

# Remove dpkg lock files.
print_message $YELLOW "Removing dpkg lock files..."
sudo rm -rf /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock 2>> $LOG_FILE
if [ $? -eq 0 ]; then
    print_message $GREEN "Lock files removed successfully."
else
    print_message $RED "Failed to remove lock files."
fi

echo ""

# Update packages.
print_message $YELLOW "Updating package lists..."
sudo apt-get update >> $LOG_FILE 2>&1
if [ $? -eq 0 ]; then
    print_message $GREEN "Package lists updated successfully."
else
    print_message $RED "Failed to update package lists."
    log_and_print $RED "Update process failed on $CURRENT_DATE at $CURRENT_TIME"
    exit 1
fi

echo ""

# Upgrade packages.
print_message $YELLOW "Upgrading packages..."
UPGRADE_LOG=$(sudo apt-get upgrade -y)
echo "$UPGRADE_LOG" >> $LOG_FILE
if [ $? -eq 0 ]; then
    print_message $GREEN "Packages upgraded successfully."
else
    print_message $RED "Failed to upgrade packages."
    log_and_print $RED "Update process failed on $CURRENT_DATE at $CURRENT_TIME"
    exit 1
fi

echo ""

# Dist upgrade.
print_message $YELLOW "Performing dist-upgrade..."
DIST_UPGRADE_LOG=$(sudo apt-get dist-upgrade -y)
echo "$DIST_UPGRADE_LOG" >> $LOG_FILE
if [ $? -eq 0 ]; then
    print_message $GREEN "Dist-upgrade completed successfully."
else
    print_message $RED "Failed to complete dist-upgrade."
    log_and_print $RED "Update process failed on $CURRENT_DATE at $CURRENT_TIME"
    exit 1
fi

echo ""

# Autoremove
print_message $YELLOW "Removing unnecessary packages..."
AUTOREMOVE_LOG=$(sudo apt-get autoremove -y)
echo "$AUTOREMOVE_LOG" >> $LOG_FILE
if [ $? -eq 0 ]; then
    print_message $GREEN "Unnecessary packages removed successfully."
else
    print_message $RED "Failed to remove unnecessary packages."
    log_and_print $RED "Update process failed on $CURRENT_DATE at $CURRENT_TIME"
    exit 1
fi

echo ""

# Autoclean
print_message $YELLOW "Cleaning up..."
AUTOCLEAN_LOG=$(sudo apt-get autoclean -y)
echo "$AUTOCLEAN_LOG" >> $LOG_FILE
if [ $? -eq 0 ]; then
    print_message $GREEN "Cleanup completed successfully."
else
    print_message $RED "Failed to clean up."
    log_and_print $RED "Update process failed on $CURRENT_DATE at $CURRENT_TIME"
    exit 1
fi

echo ""

# Summary
print_message $CYAN "SUMMARY"
print_message $CYAN "===================="
INSTALLED_PACKAGES=$(echo "$UPGRADE_LOG" "$DIST_UPGRADE_LOG" | grep -E '^(Inst)' | wc -l)
REMOVED_PACKAGES=$(echo "$AUTOREMOVE_LOG" | grep -E '^(Remv)' | wc -l)
HELD_BACK=$(echo "$UPGRADE_LOG" | grep -E '^(Conf)' | wc -l)
TOTAL_PACKAGES=$((INSTALLED_PACKAGES + REMOVED_PACKAGES))
UPGRADE_SIZE=$(echo "$UPGRADE_LOG" | grep "After this operation" | awk '{print $5, $6}')
DIST_UPGRADE_SIZE=$(echo "$DIST_UPGRADE_LOG" | grep "After this operation" | awk '{print $5, $6}')
TOTAL_UPGRADE_SIZE="NA"
if [ -n "$UPGRADE_SIZE" ] || [ -n "$DIST_UPGRADE_SIZE" ]; then
    TOTAL_UPGRADE_SIZE="${UPGRADE_SIZE} ${DIST_UPGRADE_SIZE}"
fi
print_message $CYAN "Installed/Upgraded packages: $INSTALLED_PACKAGES"
print_message $CYAN "Removed packages: $REMOVED_PACKAGES"
print_message $CYAN "Held-back packages: $HELD_BACK"
print_message $CYAN "Total upgrade size: $TOTAL_UPGRADE_SIZE"
print_message $CYAN "===================="
log "Installed/Upgraded packages: $INSTALLED_PACKAGES"
log "Removed packages: $REMOVED_PACKAGES"
log "Held-back packages: $HELD_BACK"
log "Total upgrade size: $TOTAL_UPGRADE_SIZE"

echo ""

print_message $WHITE "Press Enter to exit."
read -r

exit 0

# THE END
