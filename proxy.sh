#!/bin/bash

# Ask if the user wants to delete all iptables rules
read -p "Would you like to delete all iptables rules first? (yes/no) [default: no]: " delete_rules
delete_rules=${delete_rules:-no}

# Delete all iptables rules if the user chooses "yes"
if [[ "$delete_rules" == "yes" ]]; then
    echo "Deleting all iptables rules..."
    
    # Reset using iptables-legacy
    if command -v iptables-legacy &> /dev/null; then
        sudo iptables-legacy -F
        sudo iptables-legacy -t nat -F
        sudo iptables-legacy -t mangle -F
        sudo iptables-legacy -X
        sudo iptables-legacy -P INPUT ACCEPT
        sudo iptables-legacy -P FORWARD ACCEPT
        sudo iptables-legacy -P OUTPUT ACCEPT
        sudo iptables-legacy-save > /etc/iptables/rules.v4
        echo "iptables-legacy rules reset and saved."
    fi
    
    # Reset using iptables
    if command -v iptables &> /dev/null; then
        sudo iptables -F
        sudo iptables -t nat -F
        sudo iptables -t mangle -F
        sudo iptables -X
        sudo iptables -P INPUT ACCEPT
        sudo iptables -P FORWARD ACCEPT
        sudo iptables -P OUTPUT ACCEPT
        sudo iptables-save > /etc/iptables/rules.v4
        echo "iptables rules reset and saved."
    fi

    echo "All iptables rules have been deleted."
fi

# Ask for input values
read -p "Proxy (external) IP to SNAT to: " proxy_ip
read -p "Node (internal) IP to DNAT to: " node_ip
read -p "Port or port range(s) to forward (e.g. 8080,2022,25565:25664): " ports

# Apply iptables rules
for port in $(echo $ports | tr ',' '\n'); do
    # Forward TCP and UDP ports
    sudo iptables -t nat -A PREROUTING -p tcp --dport $port -j DNAT --to-destination $node_ip
    sudo iptables -t nat -A PREROUTING -p udp --dport $port -j DNAT --to-destination $node_ip
    sudo iptables -t nat -A POSTROUTING -p tcp -d $node_ip --dport $port -j SNAT --to-source $proxy_ip
    sudo iptables -t nat -A POSTROUTING -p udp -d $node_ip --dport $port -j SNAT --to-source $proxy_ip

    echo "Forwarding TCP port(s) $port → $node_ip  SNAT via $proxy_ip"
    echo "Forwarding UDP port(s) $port → $node_ip  SNAT via $proxy_ip"
done

echo "All rules applied."

# Check if iptables-legacy is available and use it if present
if command -v iptables-legacy-save &> /dev/null; then
    iptables-legacy-save > /etc/iptables/rules.v4
    echo "Rules saved using iptables-legacy-save."
else
    iptables-save > /etc/iptables/rules.v4
    echo "Rules saved using iptables-save."
fi

# List all the current iptables rules in the nat table
echo "Listing current iptables rules in the nat table:"
sudo iptables -t nat -L -v -n
