## **Overview**  
Restore **offline WiFi configuration** on headless Raspberry Pi OS (Bookworm) using a standard `wpa_supplicant.conf` file.  

`configure-wifi.sh` is a script that **converts legacy `wpa_supplicant.conf` files into NetworkManager-compatible `.nmconnection` files** on Raspberry Pi OS (Bookworm).  
### **Why is this needed?**  
In previous versions of Raspberry Pi OS, you could simply drop a `wpa_supplicant.conf` file into the boot partition to configure WiFi before first boot—**a crucial feature for headless setups**. However, this functionality has been **removed** in Bookworm, and **no direct replacement exists**.  

This script provides a stopgap solution which essentially **restores that functionality** by allowing users to **pre-configure WiFi networks** offline.  

### **Install/How it Works**  
- Place a `wpa_supplicant.conf` file in the `/boot/` directory of your SD card.
- Download the script and also place it in the `/boot/` directory.
- Modify `cmdline.txt` in the `/boot/` directory by appending `init=/boot/firmware/configure-wifi.sh` (ensure it is all on a single line).
- Place the SD card into the Raspberry Pi and reboot.
- On startup, the script will run and **parse wpa_supplicant.conf** and generates `.nmconnection` files for each network.  
- **NetworkManager is restarted**, applying the new WiFi configurations automatically. 

### **References**  
- [Raspberry Pi OS Bookworm - Missing WiFi Configuration](https://github.com/raspberrypi/bookworm-feedback/issues/72)  
- [Raspberry Pi Forums Discussion](https://forums.raspberrypi.com/viewtopic.php?t=357623)  

### **Compatibility**  
- Tested working on Raspberry Pi 4 Model B running 64 bit Raspberry Pi OS Lite (Debian Bookworm port)
- Could not get the script to run on-boot on Raspberry Pi 3 Model B v1.2 also running 64 bit Raspberry Pi OS Lite (Debian Bookworm port)

### Example wpa_supplicant.conf file:
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
