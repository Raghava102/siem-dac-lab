#!/usr/bin/env bash
# Run on KALI at the start of every lab session.
# Kali is a live USB: IP, clock and tooling reset on every boot, so this
# re-establishes the known state before any attack runs.

set -uo pipefail

HOTSPOT="Vishnu Raghava"
KALI_IP="172.20.10.14/28"
GATEWAY="172.20.10.1"
WAZUH="172.20.10.12"
WIN="172.20.10.13"

echo "[*] 1/4  Clock -> UTC + NTP"
sudo timedatectl set-ntp true
sudo timedatectl set-timezone UTC
sleep 2
echo "    $(date -u '+%Y-%m-%dT%H:%M:%SZ')"

echo "[*] 2/4  Joining hotspot and pinning $KALI_IP"
nmcli device wifi connect "$HOTSPOT" 2>/dev/null || \
  echo "    (already connected, or run: nmcli device wifi connect \"$HOTSPOT\" --ask)"
nmcli connection modify "$HOTSPOT" ipv4.method manual \
  ipv4.addresses "$KALI_IP" ipv4.gateway "$GATEWAY" ipv4.dns "8.8.8.8"
nmcli connection down "$HOTSPOT" >/dev/null 2>&1
nmcli connection up   "$HOTSPOT" >/dev/null 2>&1

IP_NOW="$(ip -4 addr show | grep -oP '(?<=inet\s)172\.20\.10\.\d+' | head -1)"
echo "    IP now: ${IP_NOW:-NONE}"
if [ "${IP_NOW:-}" != "172.20.10.14" ]; then
  echo "    !! Not on 172.20.10.14 — fix before attacking. Wrong network resets everything."
  exit 1
fi

echo "[*] 3/4  Reachability"
ping -c 2 -W 2 "$WAZUH" >/dev/null && echo "    Ubuntu  $WAZUH  reachable" \
  || echo "    !! Ubuntu unreachable"
ping -c 2 -W 2 "$WIN" >/dev/null && echo "    Windows $WIN  reachable" \
  || echo "    !! Windows unreachable (VM may be off)"

echo "[*] 4/4  Wordlist"
WL="$HOME/lab-wordlist.txt"
if [ ! -f "$WL" ]; then
  printf 'password\n123456\nadmin\nletmein\nwelcome\nqwerty\nlabtarget\nchangeme\n' > "$WL"
  echo "    created $WL"
else
  echo "    $WL exists ($(wc -l < "$WL") entries)"
fi

echo
echo "[+] Session ready. Pull the attack scripts from Ubuntu:"
echo "    scp -r project@$WAZUH:~/siem-dac-lab/attacks ~/"
