# Baseline — default Wazuh ruleset, before custom rules

Captured 2026-09-17 | Wazuh 4.14.7 | log_alert_level 3
Hosts: kali 172.20.10.14 | ubuntu/manager 172.20.10.12 | win10-ep01 172.20.10.13
Sysmon 15.22, SwiftOnSecurity config (schema 4.50)

## Headline
| Event | Default ruleset response |
|---|---|
| PowerShell script-policy test file in %TEMP% (benign) | rule 92213, level 15 CRITICAL, T1105 — fired 33x |
| powershell.exe -> 172.20.10.14:4444 outbound C2 | NO ALERT (0 of 2 attempts) |

Sysmon EID 3 captured both connections in full (image, user,
protocol, initiated=true, src/dst ip and port). Events reached
archives.json only; never alerts.json.

Attempts: 2026-09-17T06:31:34Z and 2026-09-17T06:34:29Z

## Alert volume, 24h, before attacks
Critical 28 | High 1 | Medium 799 | Low 568 | Total 1396

## Documented default-ruleset false positives
- 92213 L15 T1105 — PowerShell temp policy file. Reproducible every run.
- 510 L7 — rootcheck flags /bin/cat /bin/chmod /bin/chown /bin/uname
  as trojaned. Stock Ubuntu coreutils. 16+ fires.

## Per-technique default coverage
| Technique | MITRE | Coverage | Rule | Level |
|---|---|---|---|---|
| PowerShell execution | T1059.001 | PARTIAL - spawn only, no cmdline inspection | 92027 | 4 |
| Reverse shell / C2 | T1571 | NONE | - | - |
| Port scan | T1046 | TBD | | |
| SSH brute force | T1110.001 | TBD | | |

## Result — rule 100130

Deployed 2026-09-17. Confirmed firing 2026-09-17T22:31:50+0530.
Chains from built-in rule 92101 via if_sid.

| Event | Default ruleset | With 100130 |
|---|---|---|
| PowerShell temp policy file (benign) | 92213, level 15 CRITICAL, 67x | unchanged |
| PowerShell -> 4444 outbound C2 | no alert | 100130, level 12, T1059.001 + T1571 |

Root cause of default gap: rule 92101 ("Powershell process
communicating over TCP") is level 0 — matches but suppresses.
Its only children are 92102 (port 135, DCOM) and 92103
(port 389, LDAP). No coverage for arbitrary C2 ports.

## Finding — telemetry config gates detection
Rule 100130 was logically correct but produced zero alerts for
several hours because DestinationPort 4444 had been added to the
NetworkConnect onmatch="exclude" block of the Sysmon config.
Sysmon exclude overrides include, so the event was never emitted.
Nothing in the SIEM indicated the rule was blind. Detection
coverage is gated by telemetry configuration independently of
rule logic.
