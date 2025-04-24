# Iptables‑Proxy

Simple script to forward ports via DNAT/SNAT on Ubuntu.

If anyone has any improvements I could make to the proxy to run better, please let me (Exp) know through Discord.

## Usage

1. **If you can log in as `root`:**

   ```bash
   bash <(curl -fsSL https://raw.githubusercontent.com/exphost-net/Iptables-Proxy/main/proxy.sh)
   ```

2. **If you need `sudo`:**

   ```bash
   curl -fsSL https://raw.githubusercontent.com/exphost-net/Iptables-Proxy/main/proxy.sh | sudo bash
   ```

---

### What it does

- Prompts for:
  - External (proxy) IP
  - Internal (node) IP
  - Port(s) or range(s) to forward (e.g. `8080,2022,25565:25664`)
- Adds `iptables -t nat` rules:
  - **PREROUTING** → `DNAT` to your node IP
  - **POSTROUTING** → `SNAT` via your proxy IP
- Saves rules to `/etc/iptables/rules.v4`
  - Tries `iptables-save` first
  - Falls back to `iptables-legacy-save` if needed

---
