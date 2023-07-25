#!/bin/bash

# Function to install required packages
install_packages() {
  sudo apt update
  sudo apt install -y isc-dhcp-server iptables-persistent
}

# Function to configure WAN interface
configure_wan_interface() {
  read -p "Enter your WAN interface name (e.g., eth0): " wan_interface
  cat <<EOF | sudo tee /etc/network/interfaces
source /etc/network/interfaces.d/*
# Network is managed by Network manager
auto lo
iface lo inet loopback
auto $wan_interface
iface $wan_interface inet dhcp
EOF
}

# Function to enable IP forwarding
enable_ip_forwarding() {
  sudo sed -i '/^#net.ipv4.ip_forward=1/s/^#//' /etc/sysctl.conf
  sudo sysctl -p
}

# Function to configure LAN interface
configure_lan_interface() {
  read -p "Enter your LAN interface name (e.g., eth1): " lan_interface
  read -p "Enter the desired LAN IP address (e.g., 192.168.10.1): " lan_ip
  read -p "Enter the LAN subnet (e.g., 192.168.10.0/24): " lan_subnet
  cat <<EOF | sudo tee -a /etc/network/interfaces
auto $lan_interface
iface $lan_interface inet static
  address $lan_ip
  netmask $lan_subnet
EOF
}

# Function to configure DHCP server
configure_dhcp_server() {
  read -p "Enter the DHCP range start address (e.g., 192.168.10.100): " dhcp_range_start
  read -p "Enter the DHCP range end address (e.g., 192.168.10.200): " dhcp_range_end
  read -p "Enter the primary DNS server address (e.g., 8.8.8.8): " dns_primary
  read -p "Enter the secondary DNS server address (e.g., 8.8.4.4): " dns_secondary

  cat <<EOF | sudo tee /etc/dhcp/dhcpd.conf
subnet $lan_subnet {
  range $dhcp_range_start $dhcp_range_end;
  option routers $lan_ip;
  option domain-name-servers $dns_primary, $dns_secondary;
}
EOF

  sudo systemctl enable isc-dhcp-server
  sudo service isc-dhcp-server start
}

# Function to configure NAT
configure_nat() {
  sudo iptables -t nat -A POSTROUTING -o $wan_interface -j MASQUERADE
  sudo netfilter-persistent save
}

# Function to reboot
reboot_system() {
  echo "Configuration complete. Rebooting the system..."
  sleep 3
  sudo reboot
}

# Main script
echo "Setting up Armbian as a router..."

install_packages
configure_wan_interface
enable_ip_forwarding
configure_lan_interface
configure_dhcp_server
configure_nat
reboot_system
