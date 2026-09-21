# Day 3 runbook

Files in this bundle:
- `attacks/_log.sh`            shared logger, writes logs/attack_log.csv
- `attacks/T1110_ssh_brute.sh` hydra vs Ubuntu SSH  (T1110.001)
- `attacks/T1046_portscan.sh`  nmap vs Ubuntu       (T1046)
- `scripts/session-start.sh`   Kali boot setup (IP, clock, wordlist)
- `rules/110-windows-powershell.xml`  4 custom rules for T1059.001

All paths assume the repo lives at `~/siem-dac-lab`.

---

## 0. Put these in the repo (on Ubuntu)

Copy the files into the repo tree, then commit:

    cd ~/siem-dac-lab
    chmod +x attacks/*.sh scripts/*.sh
    git add -A && git commit -m "day 3: attack scripts, session-start, T1059 rules" && git push

---

## 1. Bring Kali up

On Kali (live USB — nothing persists):

    bash session-start.sh      # after copying it over, or paste the commands

Must end with IP = 172.20.10.14 and both hosts reachable. If not, stop.

Pull the attack scripts:

    scp -r project@172.20.10.12:~/siem-dac-lab/attacks ~/
    chmod +x ~/attacks/*.sh

---

## 2. SSH brute force  (T1110.001)  — default coverage

Watch on Ubuntu:

    sudo tail -f /var/ossec/logs/alerts/alerts.json | grep -vi rootcheck

Attack from Kali, several rates:

    ~/attacks/T1110_ssh_brute.sh 172.20.10.12 4
    ~/attacks/T1110_ssh_brute.sh 172.20.10.12 1     # evasion case
    ~/attacks/T1110_ssh_brute.sh 172.20.10.12 16

Expect rule 5712. Record its level and whether -t 1 still triggers it.
Capture the fixture (Ubuntu):

    sudo grep "Failed password" /var/log/auth.log | tail -20 \
      > ~/siem-dac-lab/fixtures/T1110_ssh_fail.log

This is the third row of the baseline: a technique the DEFAULT ruleset
already covers. It completes the coverage spread:
  T1059.001 partial (92027) | T1571 none -> 100130 | T1110.001 full (5712)

---

## 3. Port scan  (T1046)  — no default coverage

    ~/attacks/T1046_portscan.sh 172.20.10.12 -T4
    ~/attacks/T1046_portscan.sh 172.20.10.12 -T1     # slow / evasion

Capture the fixture (Ubuntu) — note the SRC filter makes it a scan, not noise:

    sudo grep "UFW BLOCK" /var/log/ufw.log | grep "SRC=172.20.10.14" | tail -20 \
      > ~/siem-dac-lab/fixtures/T1046_portscan_ufw.log
    wc -l ~/siem-dac-lab/fixtures/T1046_portscan_ufw.log

The port-scan custom rule (100101) + UFW decoder is the next rule to write,
once you have a non-empty fixture to test against.

---

## 4. Deploy the T1059.001 rules  (on Ubuntu)

    sudo cp ~/siem-dac-lab/rules/110-windows-powershell.xml /var/ossec/etc/rules/
    sudo chown wazuh:wazuh /var/ossec/etc/rules/110-windows-powershell.xml
    sudo chmod 660 /var/ossec/etc/rules/110-windows-powershell.xml
    sudo systemctl restart wazuh-manager
    sleep 15
    sudo systemctl is-active wazuh-manager

If the manager is NOT active, the XML has a syntax error:

    sudo /var/ossec/bin/wazuh-logtest   # will print the parse error on start

---

## 5. Generate the events  (on Windows VM)

PowerShell is damaged on this guest, so use the type-accelerator form and
plain string args. Each command spawns powershell.exe with a suspicious
command line that Sysmon EID 1 records. These are benign no-ops — they
fetch nothing and run nothing external — they only produce the pattern.

Encoded command (rule 100120). This is Base64 for `Write-Output hi`:

    powershell -e VwByAGkAdABlAC0ATwB1AHQAcAB1AHQAIABoAGkA

Download-cradle pattern (rule 100121) — note it points nowhere real:

    powershell -c "'Invoke-WebRequest downloadstring net.webclient' | Out-Null"

Stealth flags (rule 100122):

    powershell -nop -w hidden -c "Get-Date | Out-Null"

In-memory primitive (rule 100123):

    powershell -c "'iex invoke-expression' | Out-Null"

---

## 6. Confirm detections  (on Ubuntu)

    sleep 30
    for id in 100120 100121 100122 100123; do
      c=$(sudo grep -c "\"id\":\"$id\"" /var/ossec/logs/alerts/alerts.json)
      echo "rule $id: $c alert(s)"
    done

Any non-zero count = that rule fires. Inspect one:

    sudo grep '"id":"100120"' /var/ossec/logs/alerts/alerts.json | tail -1 | python3 -m json.tool

Screenshot each in the dashboard: Threat Hunting -> filter rule.id.

---

## 7. Commit results

    cd ~/siem-dac-lab
    git add -A
    git commit -m "day 3: T1110 + T1046 runs, T1059 rules confirmed"
    git push

---

## Note if the T1059 rules do NOT fire

If step 6 is all zeros but the events show in the dashboard at level 4
(rule 92027 only), the anchor is wrong for your build. Fix:

1. Trigger one event, open it, read its real rule.id and rule.groups.
2. In 110-windows-powershell.xml replace
       <if_sid>92027,92004,92003</if_sid>
   with
       <if_group>sysmon_eid1_detections</if_group>
   on each rule.
3. Redeploy (step 4) and re-test (step 6).

This is the same anchor-discovery process that made 100130 work: the
parent rule id must come from YOUR install, not from a tutorial.
