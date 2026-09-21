#!/usr/bin/env bash
cd ~/siem-dac-lab
git add -A
git commit -m "lab session $(date -u +%Y-%m-%dT%H:%MZ)" || exit 0
git push
