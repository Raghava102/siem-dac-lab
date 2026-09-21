#!/usr/bin/env bash
# T1046 - Network Service Discovery
# SYN scan against the Ubuntu host. UFW logs the blocked probes to
# /var/log/ufw.log, which Wazuh reads. Detection depends on custom rule
# 100101 (to be written) matching a burst of UFW BLOCK from one source.
#
# Usage:  ./T1046_portscan.sh [target_ip] [timing]
#   target_ip  default 172.20.10.12
#   timing     default -T4   (vary -T5 fast .. -T1 slow)
#
# -T1 is the evasion case: probes spread wide enough to fall outside a
# 60s correlation window. Record whether the rule still fires.

set -uo pipefail
source "$(dirname "$0")/_log.sh"

TARGET="${1:-172.20.10.12}"
TIMING="${2:--T4}"
EXPECTED_RULE="100101"   # custom rule, written on the rules day

CMD="nmap -sS -p1-1000 $TIMING $TARGET"

echo "[*] T1046 port scan"
echo "    target : $TARGET"
echo "    timing : $TIMING"
echo

START=$(now_utc)
echo "[*] start $START"
sudo $CMD
END=$(now_utc)
echo "[*] end   $END"

log_attack "$(next_run_id)" "$START" "$END" "Port scan" "T1046" \
  "kali-attacker" "$TARGET" "$CMD" "$EXPECTED_RULE" "$TIMING" "syn scan"

echo
echo "[i] On Ubuntu, capture the fixture (only if this was a real scan from .14):"
echo "    sudo grep 'UFW BLOCK' /var/log/ufw.log | grep 'SRC=172.20.10.14' | tail -20 \\"
echo "      > ~/siem-dac-lab/fixtures/T1046_portscan_ufw.log"
