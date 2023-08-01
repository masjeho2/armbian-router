#!/bin/bash

# Function to install required packages
install_packages() {
  sudo apt update
  sudo apt install -y iptables-persistent
}

# Function to install Pi-hole as DHCP server
install_pihole_dhcp() {
  curl -sSL https://install.pi-hole.net | bash
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
  sudo sysctl -w net.ipv4.ip_forward=1
  sudo sed -i '/^net.ipv4.ip_forward=1/s/^#//; /^net.ipv4.ip_forward=/s/0/1/' /etc/sysctl.conf
}

# Function to configure LAN interface
configure_lan_interface() {
  read -p "Enter your LAN interface name (e.g., eth1): " lan_interface
  lan_interface=${lan_interface:-eth1}
  read -p "Enter the desired LAN IP address (e.g., 192.168.10.1): " lan_ip
  lan_ip=${lan_ip:-192.168.10.1}
  read -p "Enter the LAN netmask (e.g., 255.255.255.0): " lan_netmask
  lan_netmask=${lan_netmask:-255.255.255.0}

  cat <<EOF | sudo tee -a /etc/network/interfaces
auto $lan_interface
iface $lan_interface inet static
  address $lan_ip
  netmask $lan_netmask
EOF
}

# Function to configure DHCP server for Pi-hole
configure_pihole_dhcp() {
  read -p "Enter the DHCP range start address (e.g., 192.168.10.100): " dhcp_range_start
  dhcp_range_start=${dhcp_range_start:-192.168.10.100}
  read -p "Enter the DHCP range end address (e.g., 192.168.10.200): " dhcp_range_end
  dhcp_range_end=${dhcp_range_end:-192.168.10.200}

  cat <<EOF | sudo tee /etc/dnsmasq.d/99-pihole-dhcp.conf
dhcp-range=$lan_ip,$dhcp_range_start,$dhcp_range_end,24h
dhcp-option=option:router,$lan_ip
EOF

  sudo systemctl restart dnsmasq
}

# Function to configure NAT and firewall
configure_nat_and_firewall() {
  # Flush existing rules and set default policies to drop all incoming packets.
  sudo iptables -F
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

  # Save the firewall rules
  sudo netfilter-persistent save
}

# Function to reboot
reboot_system() {
  echo "Configuration complete. Rebooting the system..."
  sleep 3
  sudo reboot
}

# Main script
echo "Setting up Armbian as a router with Pi-hole as DHCP server..."

install_packages
configure_wan_interface
enable_ip_forwarding
configure_lan_interface
install_pihole_dhcp
configure_pihole_dhcp
configure_nat_and_firewall
reboot_system
