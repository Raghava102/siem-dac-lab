#!/usr/bin/env bash
# Sourced by every attack script. Appends one row to logs/attack_log.csv.
# The attack log is the GROUND TRUTH for the confusion matrix: what was
# actually executed, versus what Wazuh detected.

ATTACK_LOG="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/logs/attack_log.csv"

# Create the header once, if the file does not exist yet.
init_log() {
  if [ ! -f "$ATTACK_LOG" ]; then
    mkdir -p "$(dirname "$ATTACK_LOG")"
    echo "run_id,start_utc,end_utc,technique,mitre_id,source_host,target_host,command,expected_rule_id,variant,notes" > "$ATTACK_LOG"
  fi
}

now_utc() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }

# Next run id: R + zero-padded count of existing data rows.
next_run_id() {
  init_log
  printf 'R%03d' "$(( $(wc -l < "$ATTACK_LOG") ))"
}

# log_attack run_id start end technique mitre src dst command rule variant [notes]
log_attack() {
  init_log
  local run_id="$1" start="$2" end="$3" technique="$4" mitre="$5"
  local src="$6" dst="$7" cmd="$8" rule="$9" variant="${10}" notes="${11:-}"
  printf '%s,%s,%s,%s,%s,%s,%s,"%s",%s,%s,%s\n' \
    "$run_id" "$start" "$end" "$technique" "$mitre" \
    "$src" "$dst" "$cmd" "$rule" "$variant" "$notes" >> "$ATTACK_LOG"
  echo "[+] logged $run_id: $technique ($variant)"
}
