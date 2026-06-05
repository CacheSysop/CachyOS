#!/usr/bin/env bash

# Arch/CachyOS KVM & Libvirt automated installer
# Includes Windows guest prep and NetworkManager bridging.

# Color variables for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root. Try: sudo ./install-kvm.sh${NC}"
   exit 1
fi

echo -e "${BLUE}=== Starting KVM / QEMU / Libvirt Setup ===${NC}\n"

# 1. Check for Hardware Virtualization Support
echo -e "${YELLOW}Checking for CPU Virtualization support (VT-x / AMD-V)...${NC}"
if LC_ALL=C lscpu | grep -i 'Virtualization' > /dev/null; then
    echo -e "${GREEN}Hardware virtualization is supported and enabled.${NC}"
else
    echo -e "${RED}Warning: Hardware virtualization not detected in CPU flags.${NC}"
    echo "Ensure it is enabled in your BIOS/UEFI settings before creating VMs."
    sleep 2
fi

# 2. Install Core Packages
echo -e "\n${YELLOW}Installing necessary Arch Linux packages...${NC}"
# qemu-full: The emulator itself (includes audio/usb/video backends)
# libvirt & virt-manager: The daemon and GUI manager
# edk2-ovmf & swtpm: UEFI firmware and TPM 2.0 emulator (Required for Windows 11)
# dnsmasq & iptables-nft: Required for the default NAT 'virbr0' network
pacman -S --needed --noconfirm \
    qemu-full \
    qemu-img \
    libvirt \
    virt-install \
    virt-manager \
    virt-viewer \
    edk2-ovmf \
    dnsmasq \
    swtpm \
    guestfs-tools \
    iptables-nft \
    wget

# 3. Enable Systemd Services
echo -e "\n${YELLOW}Enabling and starting the libvirtd daemon...${NC}"
systemctl enable --now libvirtd.service

# Ensure the default NAT network starts automatically
virsh net-autostart default > /dev/null 2>&1
virsh net-start default > /dev/null 2>&1

# 4. User Group Configuration
echo -e "\n${YELLOW}Configuring user permissions...${NC}"
if [ -n "$SUDO_USER" ]; then
    usermod -aG libvirt,kvm "$SUDO_USER"
    echo -e "${GREEN}Added user '$SUDO_USER' to the 'libvirt' and 'kvm' group.${NC}"
    echo "(Note: You will need to log out and log back in for group changes to take effect)."
fi

# 5. Windows Guest Preparation (VirtIO Drivers)
echo -e "\n${YELLOW}Preparing Windows Guest Drivers (virtio-win)...${NC}"
ISO_DIR="/var/lib/libvirt/images"
ISO_URL="https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso"
ISO_DEST="$ISO_DIR/virtio-win.iso"

if [ ! -f "$ISO_DEST" ]; then
    echo "Downloading the latest stable Windows VirtIO drivers..."
    wget -q --show-progress -O "$ISO_DEST" "$ISO_URL"
    echo -e "${GREEN}VirtIO ISO downloaded to $ISO_DEST${NC}"
else
    echo "VirtIO ISO already exists at $ISO_DEST. Skipping download."
fi

# 6. Interactive Network Bridge Setup (via NetworkManager)
setup_bridge() {
    echo -e "\n${BLUE}--- Network Bridge Setup ---${NC}"
    echo "Bridged networking allows your VMs to appear on your physical network and get their own IP from your router."
    echo -e "${RED}CRITICAL: Bridging generally only works on WIRED Ethernet connections. Do not attempt on Wi-Fi.${NC}"

    read -p "Do you want to configure a NetworkManager bridge right now? (y/N): " setup_br
    if [[ "$setup_br" =~ ^[Yy]$ ]]; then
        echo -e "\nActive Network Interfaces:"
        ip -o link show | awk -F': ' '{print $2}' | grep -v 'lo'

        echo ""
        read -p "Enter the physical interface name you want to bridge (e.g., enp3s0): " iface
        read -p "Enter a name for your bridge (default: br0): " brname
        brname=${brname:-br0}

        if ip link show "$iface" > /dev/null 2>&1; then
            echo -e "${YELLOW}Creating bridge $brname using $iface...${NC}"

            # Create the bridge and attach the physical interface
            nmcli conn add type bridge con-name "$brname" ifname "$brname" stp no
            nmcli conn add type ethernet slave-type bridge con-name "eth0-$iface" ifname "$iface" master "$brname"

            # Bring up the newly created bridge
            nmcli conn up "$brname"

            echo -e "${GREEN}Bridge '$brname' created and activated successfully!${NC}"
            echo -e "You can now select '$brname' as the network source in Virt-Manager."
        else
            echo -e "${RED}Error: Interface '$iface' not found. Skipping bridge setup.${NC}"
        fi
    else
        echo "Skipping bridge setup. Your VMs will use the default NAT (virbr0) network."
    fi
}

setup_bridge

echo -e "\n${BLUE}=== Setup Complete! ===${NC}"
echo "Please REBOOT your system or fully log out/in to apply group permissions."
