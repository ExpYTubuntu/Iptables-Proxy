set -euo pipefail

read -rp "Proxy (external) IP to SNAT to: " PROXY_IP
read -rp "Node (internal) IP to DNAT to: " NODE_IP
read -rp "Port or port range(s) to forward (e.g. 8080,2022,25565:25664): " PORTS

add_rules() {
  local proto=$1
  local port_spec=$2

  sudo iptables -t nat -A PREROUTING -p "$proto" --dport "$port_spec" \
    -j DNAT --to-destination "$NODE_IP"
  sudo iptables -t nat -A POSTROUTING -p "$proto" -d "$NODE_IP" --dport "$port_spec" \
    -j SNAT --to-source "$PROXY_IP"
}

IFS=',' read -r -a PORT_ARRAY <<< "$PORTS"

for PORT_SPEC in "${PORT_ARRAY[@]}"; do
  echo "Forwarding TCP port(s) $PORT_SPEC → $NODE_IP  SNAT via $PROXY_IP"
  add_rules tcp "$PORT_SPEC"
  echo "Forwarding UDP port(s) $PORT_SPEC → $NODE_IP  SNAT via $PROXY_IP"
  add_rules udp "$PORT_SPEC"
done

echo "All rules applied."

if command -v iptables-legacy-save &> /dev/null; then
    iptables-legacy-save > /etc/iptables/rules.v4
    echo "Rules saved using iptables-legacy-save."
else
    iptables-save > /etc/iptables/rules.v4
    echo "Rules saved using iptables-save."
fi
