## SACRILEGE
Linux automation scripts

Make sure you read all scripts before running them on your computer.

Shit can hit the fan if you just download and run scripts from the internet all willy nilly.

### debian-update.sh
Complete Debian 12 update the "right" way.
- Removes dpkg lock files.
- Updates package lists.
- Updates packages.
- dist-upgrade
- autoremove
- autoclean

### arch-update.sh
Same as debian-update.sh, but for Arch.

### arch-cac.sh
Get a DoD CAC working on any Arch based distro.
Currently, only Firefox is supported. Chrome is in the works.
- Installing necessary packages.
- Installing middleware.
- Starting CAC driver service.
- Downloading DoD certificates.
- Installing certificates on your system.
- Installing certificates to Firefox.

### Clone this repository 
```
git clone https://github.com/large-farva/sacrilege.git
```

### Make sure scripts are executable after cloning.
```
# Example:
chmod +x arch-cac.sh
./arch-cac.sh
```
### Logs
All sacrilege scripts logs are stored in ~/.logs.

~/.logs is NOT standard practice, but I like to keep logs for my custom scripts seperate.

Change the script to deposit the logs where you want them.
