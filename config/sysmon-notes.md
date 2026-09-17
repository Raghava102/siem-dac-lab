# Sysmon configuration

Base: SwiftOnSecurity sysmonconfig-export.xml
Fetched from github.com/SwiftOnSecurity/sysmon-config (master)
Config schema 4.50 against Sysmon 15.22 (schema 4.91)

Installed:  Sysmon64.exe -accepteula -i sysmonconfig-export.xml
Reloaded:   Sysmon64.exe -c sysmonconfig-export.xml

## No modifications required for T1571 detection
Line 354 of the upstream config already includes:
  <DestinationPort name="Alert,Metasploit" condition="is">4444</DestinationPort>
inside <NetworkConnect onmatch="include">.

## Incident during development
Six DestinationPort entries (4444, 4445, 1337, 9001, 8080, 8443)
were mistakenly added to the onmatch="exclude" block instead of
include. Sysmon exclude takes precedence over include, so Event ID 3
for port 4444 was suppressed entirely and rule 100130 never fired
despite being logically correct. Removing those six lines restored
detection immediately.
