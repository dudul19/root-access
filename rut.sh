#!/bin/bash
# rut.sh — nama lama, tetap ada agar link lama tidak mati.
# Script utama sekarang root-access.sh.
URL="https://raw.githubusercontent.com/dudul19/root-access/main/root-access.sh"
f=$(mktemp)
if command -v curl >/dev/null 2>&1; then curl -fsSL "$URL" -o "$f"; else wget -q -O "$f" "$URL"; fi \
    && bash "$f"; rc=$?
rm -f "$f"; exit $rc
