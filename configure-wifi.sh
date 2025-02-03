#!/bin/bash

#Add init=/boot/firmware/configure-wifi.sh to the end of cmdline.txt

BOOT_MOUNT="/boot/firmware"
WPA_SUPPLICANT_FILE="$BOOT_MOUNT/wpa_supplicant.conf"
NM_CONNECTION_DIR="/etc/NetworkManager/system-connections"

# Ensure the script is running as root
if [[ "$EUID" -ne 0 ]]; then
    echo "This script must be run as root. Exiting."
    exit 1
fi

# Function to sanitize SSID for filenames (remove special characters except dashes/underscores)
sanitize_filename() {
    echo "$1" | sed 's/[^a-zA-Z0-9_-]/_/g'
}

# Function to create .nmconnection file
create_nmconnection() {
    local ssid="$1"
    local psk="$2"
    local filename
    filename=$(sanitize_filename "$ssid")
    local file="$NM_CONNECTION_DIR/${filename}.nmconnection"

    cat <<EOF > "$file"
[connection]
id=${ssid}
uuid=$(cat /proc/sys/kernel/random/uuid)
type=wifi
autoconnect=true

[wifi]
mode=infrastructure
ssid=${ssid}

EOF

    if [[ -n "$psk" ]]; then
        # Check if PSK is inside quotes (plain-text password)
        if [[ "$psk" =~ ^\"(.+)\"$ ]]; then
            plaintext_psk="${BASH_REMATCH[1]}"  # Extract inside quotes
            cat <<EOF >> "$file"
[wifi-security]
key-mgmt=wpa-psk
psk=${plaintext_psk}
EOF
        elif [[ "$psk" =~ ^[a-fA-F0-9]{64}$ ]]; then
            # If it's a 64-character hex string WITHOUT quotes, assume it's pre-hashed
            cat <<EOF >> "$file"
[wifi-security]
key-mgmt=wpa-psk
psk=${psk}
EOF
        else
            echo "Warning: Unrecognized PSK format for SSID '$ssid'. Skipping."
        fi
    fi

    cat <<EOF >> "$file"

[ipv4]
method=auto

[ipv6]
method=auto
EOF

# Check if the file was created
if [ -f "$file" ]; then
	echo "Successfully created $file"
	
	# Set permissions for the .nmconnection file
	sudo chmod 600 "$file"
	sudo chown root:root "$file"
else
	echo "Failed to create $file"
fi
}

# Read wpa_supplicant.conf and parse networks
if [[ -f "$WPA_SUPPLICANT_FILE" ]]; then
    echo "Processing $WPA_SUPPLICANT_FILE..."
    
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*ssid= ]]; then
            ssid=$(echo "$line" | cut -d'"' -f2)
        elif [[ "$line" =~ ^[[:space:]]*psk= ]]; then
            psk=$(echo "$line" | cut -d= -f2- | tr -d '[:space:]')  # Preserve formatting
        elif [[ "$line" == "}" ]]; then
            if [[ -n "$ssid" ]]; then
                create_nmconnection "$ssid" "$psk"
            fi
            ssid=""
            psk=""
        fi
    done < "$WPA_SUPPLICANT_FILE"

    # Reload NetworkManager to apply the new connections
    echo "Reloading NetworkManager connections"
    sudo systemctl restart NetworkManager

    # Check if connections were reloaded successfully
    if systemctl is-active --quiet NetworkManager; then
        echo "NetworkManager reloaded successfully."
    else
        echo "Failed to reload NetworkManager."
    fi

else
    echo "No wpa_supplicant.conf file found in $BOOT_MOUNT."
    exit 1
fi

