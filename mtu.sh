#!/bin/bash

# Check if the script is run as root
if [[ "$EUID" -ne 0 ]]; then
    echo "❌ Please run this script as root (e.g., using sudo)."
    exit 1
fi

# Get MTU value from the first argument or prompt the user
if [[ -n "$1" ]]; then
    NEW_MTU="$1"
else
    read -p "🔧 Please enter the desired MTU value (e.g., 1450): " NEW_MTU
fi

# Validate the MTU value (should be an integer between 576 and 9000)
if ! [[ "$NEW_MTU" =~ ^[0-9]+$ ]] || [[ "$NEW_MTU" -lt 576 || "$NEW_MTU" -gt 9000 ]]; then
    echo "❌ Invalid MTU value. Please enter a number between 576 and 9000."
    exit 1
fi

echo "🔄 Setting MTU to $NEW_MTU for all valid network interfaces..."

# Get list of all network interfaces
interfaces=$(ls /sys/class/net)

# Loop through interfaces and apply MTU
for iface in $interfaces; do
    # Skip loopback and virtual interfaces
    if [[ "$iface" == "lo" || "$iface" == *"docker"* || "$iface" == *"veth"* || "$iface" == *"br-"* ]]; then
        echo "⏩ Skipping virtual or excluded interface: $iface"
        continue
    fi

    # Check if the interface is available
    if ip link show "$iface" > /dev/null 2>&1; then
        echo "✅ Setting MTU for $iface to $NEW_MTU"
        ip link set dev "$iface" mtu "$NEW_MTU"
    else
        echo "⚠️ Interface $iface is not available. Skipping."
    fi
done

echo "✅ MTU update completed successfully."
