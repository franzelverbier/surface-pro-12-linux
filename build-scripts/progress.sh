#!/bin/bash
cd /root/linux-next || exit 1
echo "heure UTC: $(date -u +%H:%M:%S)  (build lance ~15:22)"
echo "objets .o : $(find . -name '*.o' 2>/dev/null | wc -l)"
if [ -f vmlinux ]; then echo "vmlinux: OUI ($(du -h vmlinux | cut -f1))"; else echo "vmlinux: pas encore (=> phase compilation objets)"; fi
if [ -f arch/arm64/boot/Image ]; then echo "Image: $(ls -la arch/arm64/boot/Image | awk '{print $5}') octets"; else echo "Image: pas encore"; fi
echo "modules .ko deja lies: $(find . -name '*.ko' 2>/dev/null | wc -l)"
echo "process make actifs: $(pgrep -c make 2>/dev/null)"
echo "charge: $(cat /proc/loadavg)"
