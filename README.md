## Overview
Achieve legacy offline Wi-Fi configuration capability on headless Raspberry Pi OS (Bookworm) using a standard wpa_supplicant.conf file.
`configure-wifi.sh` is a script that converts a legacy `wpa_supplicant.conf` file into NetworkManager-compatible `.nmconnection` files on Raspberry Pi OS (Bookworm).  

This allows users to **pre-configure Wi-Fi networks** by placing a `wpa_supplicant.conf` file in the `/boot/` directory, similar to how it worked in previous versions of Raspberry Pi OS.

## Features
- Converts `wpa_supplicant.conf` to NetworkManager `.nmconnection` files  
- Supports **multiple networks**  
- Handles SSIDs with **spaces & special characters**  
- Supports **open & WPA-PSK networks**  
- Automatically **reloads NetworkManager** after updating connections  

---

## Installation

### **1. Copy the script to `/boot/`**
Download the script and place it in the `/boot/` directory of your SD card:

### **2. Modify cmdline.txt to run the script on boot**
Append the following to the end of /boot/cmdline.txt (ensure it is all on a single line):

`init=/boot/firmware/configure-wifi.sh`

### **3. Create a wpa_supplicant.conf file**
Place a valid wpa_supplicant.conf file in `/boot/`.

Example:
```
country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="My Home WiFi"
    psk="securepassword123"
    key_mgmt=WPA-PSK
}

network={
    ssid="Guest Network"
    key_mgmt=NONE
}
```

### **4. Replace the SD card and reboot**
On boot, the script should execute and:

- Extract networks from wpa_supplicant.conf
- Generate .nmconnection files in /etc/NetworkManager/system-connections/
- Restart NetworkManager to apply the changes
