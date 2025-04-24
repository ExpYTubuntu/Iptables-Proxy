#!/usr/bin/env bash
set -euo pipefail

# Prompt for inputs
read -rp "Proxy (external) IP to SNAT to: " PROXY_IP
read -rp "Node (internal) IP to DNAT to: " NODE_IP
read -rp "Port or port range(s) to forward (e.g. 8080,2022,25565:25664): " PORTS

# Function to add rules for a single port or port-range
add_rules() {
  local proto=$1
  local port_spec=$2

  sudo iptables -t nat -A PREROUTING -p "$proto" --dport "$port_spec" \
    -j DNAT --to-destination "$NODE_IP"
  sudo iptables -t nat -A POSTROUTING -p "$proto" -d "$NODE_IP" --dport "$port_spec" \
    -j SNAT --to-source "$PROXY_IP"
}

# Split comma-separated PORTS into an array
IFS=',' read -r -a PORT_ARRAY <<< "$PORTS"

# Loop through each port or range, for both tcp and udp
for PORT_SPEC in "${PORT_ARRAY[@]}"; do
  echo "Forwarding TCP port(s) $PORT_SPEC → $NODE_IP  SNAT via $PROXY_IP"
  add_rules tcp "$PORT_SPEC"
  echo "Forwarding UDP port(s) $PORT_SPEC → $NODE_IP  SNAT via $PROXY_IP"
  add_rules udp "$PORT_SPEC"
done

echo "All rules applied."

# Try saving with iptables-save, fallback to iptables-legacy-save
if sudo iptables-save > /etc/iptables/rules.v4; then
  echo "Rules saved to /etc/iptables/rules.v4 using iptables-save."
elif sudo iptables-legacy-save > /etc/iptables/rules.v4; then
  echo "Rules saved to /etc/iptables/rules.v4 using iptables-legacy-save."
else
  echo "Error: could not save iptables rules with either iptables-save or iptables-legacy-save." >&2
  exit 1
fi
