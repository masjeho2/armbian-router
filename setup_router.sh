#!/bin/bash

# Function to install required packages
install_packages() {
  sudo apt update
  sudo apt install -y isc-dhcp-server iptables-persistent
}

# Function to configure WAN interface
configure_wan_interface() {
  read -p "Enter your WAN interface name (e.g., eth0): " wan_interface
  wan_interface=${wan_interface:-eth0}
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
  lan_interface=${lan_interface:-eth1}
  read -p "Enter the desired LAN IP address (e.g., 192.168.10.1): " lan_ip
  lan_ip=${lan_ip:-192.168.10.1}
  read -p "Enter the LAN netmask (e.g., 255.255.255.0): " lan_netmask
  lan_netmask=${lan_netmask:-255.255.255.0}
  read -p "Enter the LAN subnet (e.g., 192.168.10.0): " lan_subnet
  lan_subnet=${lan_subnet:-192.168.10.0}

  cat <<EOF | sudo tee -a /etc/network/interfaces
auto $lan_interface
iface $lan_interface inet static
  address $lan_ip
  netmask $lan_netmask
EOF
}

# Function to configure DHCP server
configure_dhcp_server() {
  read -p "Enter the DHCP range start address (e.g., 192.168.10.100): " dhcp_range_start
  dhcp_range_start=${dhcp_range_start:-192.168.10.100}
  read -p "Enter the DHCP range end address (e.g., 192.168.10.200): " dhcp_range_end
  dhcp_range_end=${dhcp_range_end:-192.168.10.200}
  read -p "Enter the primary DNS server address (e.g., 8.8.8.8): " dns_primary
  dns_primary=${dns_primary:-8.8.8.8}
  read -p "Enter the secondary DNS server address (e.g., 8.8.4.4): " dns_secondary
  dns_secondary=${dns_secondary:-8.8.4.4}

  cat <<EOF | sudo tee -a /etc/dhcp/dhcpd.conf
subnet $lan_subnet netmask $lan_netmask {
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

# Function to configure firewall
configure_firewall() {
  # Default policy to drop all incoming packets.
  sudo iptables -P INPUT DROP
  sudo iptables -P FORWARD DROP

  # Accept incoming packets from localhost and the LAN interface.
  sudo iptables -A INPUT -i lo -j ACCEPT
  sudo iptables -A INPUT -i $lan_interface -j ACCEPT

  # Accept incoming packets from the WAN if the router initiated the connection.
  sudo iptables -A INPUT -i $wan_interface -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

  # Forward LAN packets to the WAN.
  sudo iptables -A FORWARD -i $lan_interface -o $wan_interface -j ACCEPT

  # Forward WAN packets to the LAN if the LAN initiated the connection.
  sudo iptables -A FORWARD -i $wan_interface -o $lan_interface -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

  # NAT traffic going out the WAN interface.
  sudo iptables -t nat -A POSTROUTING -o $wan_interface -j MASQUERADE
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
configure_firewall
reboot_system
