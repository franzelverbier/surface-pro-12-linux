#!/bin/bash
T=/root/sp12/vtoyboot.tar.gz
echo "fichier: $(ls -la "$T" 2>/dev/null)"
echo "=== contenu complet ==="
tar tzf "$T"
echo
echo "=== extraction ==="
rm -rf /tmp/vtoy; mkdir -p /tmp/vtoy
tar xzf "$T" -C /tmp/vtoy
echo "=== fichiers + architecture ==="
find /tmp/vtoy -type f | while read -r f; do
  printf '%s -> %s\n' "${f#/tmp/vtoy/}" "$(file -b "$f" | cut -c1-60)"
done
