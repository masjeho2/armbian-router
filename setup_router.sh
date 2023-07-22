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
  read -p "Enter the desired LAN IP address (e.g., 192.168.1.1): " lan_ip
  cat <<EOF | sudo tee -a /etc/network/interfaces
auto $lan_interface
iface $lan_interface inet static
  address $lan_ip
  netmask 255.255.255.0
EOF
}

# Function to configure DHCP server
configure_dhcp_server() {
  cat <<EOF | sudo tee /etc/dhcp/dhcpd.conf
subnet $lan_ip netmask 255.255.255.0 {
  range $lan_ip.100 $lan_ip.200;
  option routers $lan_ip;
  option domain-name-servers 8.8.8.8, 8.8.4.4;
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
