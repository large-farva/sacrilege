#!/bin/bash

# URL of the custom background image to download
IMAGE_URL="https://i.postimg.cc/fRmJRVdg/Screenshot-from-2024-05-30-13-21-59.png"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to print error message and exit
error_exit() {
    yad --title="Error" --text="Error: $1" --button="OK:1" --css=/tmp/custom.css
    rm /tmp/custom.css
    exit 1
}

# Download the custom background image
IMAGE_PATH="/tmp/custom_background.png"
wget -O "$IMAGE_PATH" "$IMAGE_URL" || error_exit "Failed to download custom background image"

# Custom CSS for Gruvbox dark palette with background image
cat <<EOF > /tmp/custom.css
window {
    background-image: url("$IMAGE_PATH");
    background-size: cover;
    background-position: center;
    color: #d79921;
    font-family: monospace;
    font-size: 12pt;
    text-shadow: 1px 1px 2px #3c3836, -1px -1px 2px #3c3836, 1px -1px 2px #3c3836, -1px 1px 2px #3c3836;
}
label {
    color: #d79921;
}
button {
    background-image: none;
    background-color: #3c3836;
    color: #d79921;
}
progressbar {
    background-color: #3c3836;
    color: #d79921;
}
EOF

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
    yad --title="Error" --text="Please run as root (use sudo)" --button="OK:1" --css=/tmp/custom.css
    rm /tmp/custom.css
    exit 1
fi

# Main menu
yad --title="CAC Setup" --text="Welcome to the CAC Setup Tool" --button="Start:0" --button="Exit:1" --css=/tmp/custom.css
if [ $? -ne 0 ]; then
    rm /tmp/custom.css
    exit 1
fi

yad --title="CAC Setup" --text="Starting CAC setup process..." --timeout=2 --no-buttons --css=/tmp/custom.css

yad --title="CAC Setup" --text="Updating system and installing necessary packages..." --progress --pulsate --auto-close --no-buttons --width=300 --css=/tmp/custom.css &
PROGRESS_PID=$!
sudo pacman -Syu --noconfirm || error_exit "Failed to update the system"
packages=(pcsclite ccid pcsc-tools opensc wget ca-certificates-utils)
for package in "${packages[@]}"; do
    sudo pacman -S --noconfirm --needed $package || error_exit "Failed to install $package"
done
kill $PROGRESS_PID

yad --title="CAC Setup" --text="Enabling and starting pcscd service..." --progress --pulsate --auto-close --no-buttons --width=300 --css=/tmp/custom.css &
PROGRESS_PID=$!
sudo systemctl enable pcscd || error_exit "Failed to enable pcscd service"
sudo systemctl start pcscd || error_exit "Failed to start pcscd service"
kill $PROGRESS_PID

yad --title="CAC Setup" --text="Downloading DoD certificates..." --progress --pulsate --auto-close --no-buttons --width=300 --css=/tmp/custom.css &
PROGRESS_PID=$!
mkdir -p ~/dod_certs
cd ~/dod_certs
wget -q https://militarycac.com/maccerts/AllCerts.p7b || error_exit "Failed to download DoD certificates"
if [ ! -f AllCerts.p7b ]; then
    error_exit "The downloaded DoD certificates file does not exist"
fi
kill $PROGRESS_PID

yad --title="CAC Setup" --text="Extracting DoD certificates..." --progress --pulsate --auto-close --no-buttons --width=300 --css=/tmp/custom.css &
PROGRESS_PID=$!
if ! openssl pkcs7 -inform DER -print_certs -in AllCerts.p7b -out dod_certs.pem; then
    error_exit "Failed to extract DoD certificates"
fi
kill $PROGRESS_PID

yad --title="CAC Setup" --text="Installing DoD certificates to the system..." --progress --pulsate --auto-close --no-buttons --width=300 --css=/tmp/custom.css &
PROGRESS_PID=$!
sudo mkdir -p /etc/ca-certificates/trust-source/anchors
sudo mv dod_certs.pem /etc/ca-certificates/trust-source/anchors/dod_certs.pem || error_exit "Failed to move DoD certificates"
kill $PROGRESS_PID

yad --title="CAC Setup" --text="Updating CA certificates..." --progress --pulsate --auto-close --no-buttons --width=300 --css=/tmp/custom.css &
PROGRESS_PID=$!
if command_exists update-ca-trust; then
    sudo update-ca-trust extract || error_exit "Failed to update CA certificates"
else
    error_exit "update-ca-trust command not found, please install ca-certificates-utils"
fi
kill $PROGRESS_PID

yad --title="CAC Setup" --text="Configuring Firefox to use CAC..." --progress --pulsate --auto-close --no-buttons --width=300 --css=/tmp/custom.css &
PROGRESS_PID=$!
firefox_profile=$(find /home -type d -name "*.default-release" -print -quit)
if [ -z "$firefox_profile" ]; then
    error_exit "Firefox profile not found"
fi
sudo tee "$firefox_profile/user.js" > /dev/null <<EOF
// Load the OpenSC module for CAC
user_pref("security.enterprise_roots.enabled", true);
user_pref("security.osclientcerts.autoload", true);
EOF

if [ $? -ne 0 ]; then
    error_exit "Failed to create user.js file in Firefox profile"
fi

kill $PROGRESS_PID

yad --title="CAC Setup" --text="Installation complete. Please restart your browser and try using your CAC." --button="OK:0" --css=/tmp/custom.css

# Clean up temporary files
rm /tmp/custom.css
rm "$IMAGE_PATH"

# End of script

