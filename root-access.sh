#!/bin/bash
# root-access.sh — aktifkan login root + password di VPS.
# Menimpa /etc/ssh/sshd_config dengan config dari repo ini (disengaja),
# config lama dibackup dan dikembalikan bila `sshd -t` gagal.
#
# Tampilan memakai desain "Struk" Tomato Autoscript: maks 40 kolom (HP
# potrait), rata kiri tanpa margin, warna truecolor.

REPO="https://raw.githubusercontent.com/dudul19/root-access/main"
CFG=/etc/ssh/sshd_config
TMP=

# Bersihkan saat keluar (selesai, gagal, atau Ctrl+C): file sementara dan
# script ini sendiri. Salinan di folder repo (ada sshd_config di sebelahnya)
# tidak ikut dihapus.
SELF=$(readlink -f "$0" 2>/dev/null)
cleanup() {
    [ -n "$TMP" ] && rm -f "$TMP"
    if [ -f "$SELF" ] && [ ! -f "${SELF%/*}/sshd_config" ]; then rm -f "$SELF"; fi
}
trap cleanup EXIT

UI_T="\e[38;2;255;122;92m"    # #ff7a5c aksen tomat
UI_G="\e[38;2;143;209;158m"   # #8fd19e
UI_OK="\e[38;2;122;214;154m"  # #7ad69a ✓
UI_D="\e[38;2;138;143;150m"   # #8a8f96 label
UI_L="\e[38;2;58;63;69m"      # #3a3f45 garis
UI_R="\e[38;2;255;107;107m"   # #ff6b6b error
UI_Y="\e[38;2;232;193;112m"   # #e8c170 peringatan
UI_N="\e[0m"
UI_W=40

ui_line() {
    local n=${2:-${UI_HRW:-40}} l
    printf -v l '%*s' "$n" ''
    echo -e "${UI_L}${l// /$1}${UI_N}"
}
ui_hr()  { ui_line ┄; }
ui_hr2() { ui_line ═; }

ui_head() {   # "TOMATO / judul ······ info kanan" + ═
    local LC_ALL=C.UTF-8 t="${1,,}" m="${2:-}" n
    n=$(( UI_W - 9 - ${#t} - ${#m} ))
    [ "$n" -lt 1 ] && n=1
    if [ -n "$m" ]; then
        printf "${UI_T}TOMATO${UI_N}${UI_D} / %s${UI_N}%*s${UI_D}%s${UI_N}\n" "$t" "$n" "" "$m"
    else
        printf "${UI_T}TOMATO${UI_N}${UI_D} / %s${UI_N}\n" "$t"
    fi
    ui_hr2
}

ui_lead() {   # "label ······ nilai" (nilai rata kanan di kolom 40)
    local LC_ALL=C.UTF-8 k="$1" v="$2" n d
    n=$(( UI_W - ${#k} - ${#v} - 2 ))
    [ "$n" -lt 2 ] && n=2
    printf -v d '%*s' "$n" ''
    printf "${UI_D}%s${UI_N} ${UI_L}%s${UI_N} %s\n" "$k" "${d// /·}" "$v"
}

ui_kv() {     # "Label      : nilai" (blok hasil, aman di-copy ke Telegram)
    printf "${UI_D}%-10s :${UI_N} %s\n" "$1" "$2"
}

ui_msg() {    # ikon + teks, dilipat 38 kolom dengan indentasi gantung
    local l first=1
    while IFS= read -r l; do
        if [ $first = 1 ]; then printf "%b %s\n" "$1" "$l"; first=0; else printf "  %s\n" "$l"; fi
    done < <(printf '%s\n' "$2" | fold -s -w 38)
}
ui_note() { printf '%s\n' "$1" | fold -s -w $UI_W | while IFS= read -r l; do printf "${UI_D}%s${UI_N}\n" "$l"; done; }
ui_ok()   { ui_msg "${UI_OK}✓${UI_N}" "$1"; }
ui_err()  { ui_msg "${UI_R}×${UI_N}" "$1"; }
ui_warn() { ui_msg "${UI_Y}!${UI_N}" "$1"; }
ui_in()   { printf "${UI_T}›${UI_N} %s" "$1"; }

fail() { ui_err "$1"; ui_hr2; echo; exit 1; }

fetch() {     # fetch <url> <file>
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL --max-time 30 "$1" -o "$2"
    else
        wget -q --timeout=30 -O "$2" "$1"
    fi
}

public_ip() {
    local ip u
    for u in https://ipinfo.io/ip https://api.ipify.org https://ifconfig.me; do
        if command -v curl >/dev/null 2>&1; then
            ip=$(curl -fsS4 --max-time 5 "$u" 2>/dev/null)
        else
            ip=$(wget -qO- --timeout=5 "$u" 2>/dev/null)
        fi
        [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && { echo "$ip"; return; }
    done
    hostname -I 2>/dev/null | awk '{print $1}'
}

os_name() {
    local PRETTY_NAME=
    [ -r /etc/os-release ] && . /etc/os-release
    echo "${PRETTY_NAME:-Linux}" | sed 's/ GNU\/Linux//; s/ (\(.*\))$//'
}

restart_ssh() {
    systemctl daemon-reload 2>/dev/null
    # Ubuntu 22.10+ memakai socket activation: port dibaca generator dari
    # sshd_config, jadi ssh.socket yang perlu direstart.
    if systemctl is-enabled ssh.socket >/dev/null 2>&1 || systemctl is-active ssh.socket >/dev/null 2>&1; then
        systemctl restart ssh.socket 2>/dev/null
        systemctl is-active ssh.service >/dev/null 2>&1 && systemctl restart ssh.service
        return 0
    fi
    systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null \
        || service ssh restart 2>/dev/null || service sshd restart 2>/dev/null
}

open_ports() {   # buka port di firewall/SELinux bila aktif (best effort)
    local p
    if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q "Status: active"; then
        for p in "${PORTS[@]}"; do ufw allow "$p/tcp" >/dev/null 2>&1; done
    fi
    if command -v firewall-cmd >/dev/null 2>&1 && firewall-cmd --state >/dev/null 2>&1; then
        for p in "${PORTS[@]}"; do firewall-cmd -q --permanent --add-port="$p/tcp" 2>/dev/null; done
        firewall-cmd -q --reload 2>/dev/null
    fi
    if command -v semanage >/dev/null 2>&1 && [ "$(getenforce 2>/dev/null)" = Enforcing ]; then
        for p in "${PORTS[@]}"; do
            semanage port -a -t ssh_port_t -p tcp "$p" 2>/dev/null || semanage port -m -t ssh_port_t -p tcp "$p" 2>/dev/null
        done
    fi
}

clear
if [ "$(id -u)" != 0 ]; then
    ui_head "ROOT ACCESS"
    fail "Run this as root. Type 'sudo su' first, then run it again."
fi

VPS_IP=$(public_ip)
OS=$(os_name)

# ── 1. Info + password ───────────────────────
ui_head "ROOT ACCESS" "${VPS_IP}"
ui_warn "This replaces /etc/ssh/sshd_config and enables root login with a password. The old config is backed up first."
ui_hr
ui_lead ip "${VPS_IP:-unknown}"
ui_lead os "$OS"
ui_lead length "min. 6 characters"
ui_hr2
echo
while :; do
    read -rsp "$(ui_in "new root password: ")" PW </dev/tty || fail "No input. Run: bash root-access.sh"; echo
    if [ ${#PW} -lt 6 ]; then ui_err "Password must be at least 6 characters."; continue; fi
    read -rsp "$(ui_in "repeat password: ")" PW2 </dev/tty || fail "No input."; echo
    if [ "$PW" != "$PW2" ]; then ui_err "Passwords do not match."; continue; fi
    break
done

# ── 2. Proses ────────────────────────────────
clear
ui_head "ROOT ACCESS" "setup"

TMP=$(mktemp)
fetch "$REPO/sshd_config" "$TMP" && grep -q '^PermitRootLogin yes' "$TMP" \
    || fail "Cannot download sshd_config. Nothing was changed."
ui_ok "sshd_config downloaded"

# Path sftp-server beda per distro (Debian/Ubuntu vs RHEL/Arch).
SFTP=internal-sftp
for f in /usr/lib/openssh/sftp-server /usr/libexec/openssh/sftp-server /usr/lib/ssh/sftp-server; do
    [ -x "$f" ] && { SFTP=$f; break; }
done
sed -i "s|^Subsystem.*sftp.*|Subsystem sftp $SFTP|" "$TMP"

mapfile -t PORTS < <(awk '/^Port /{print $2}' "$TMP")

BAK="$CFG.bak-$(date +%Y%m%d-%H%M)"
[ -f "$CFG" ] && cp -p "$CFG" "$BAK"
mkdir -p /etc/ssh /run/sshd
install -m 600 "$TMP" "$CFG"
ssh-keygen -A >/dev/null 2>&1
SSHD=$(command -v sshd || echo /usr/sbin/sshd)
if ! "$SSHD" -t 2>/dev/null; then
    [ -f "$BAK" ] && cp -p "$BAK" "$CFG"
    fail "New sshd_config failed the check (sshd -t). The old config was restored."
fi
ui_ok "sshd_config replaced"
[ -f "$BAK" ] && ui_lead backup "${BAK##*/}"

open_ports
restart_ssh || fail "Cannot restart SSH. Check: systemctl status ssh"
ui_ok "SSH restarted"

printf 'root:%s\n' "$PW" | chpasswd || fail "Cannot set the root password."
passwd -u root >/dev/null 2>&1
ui_ok "root password set"
ui_hr2
sleep 1

# ── 3. Hasil (blok 27 kolom, aman di-copy ke Telegram) ──
clear
UI_HRW=27
printf "${UI_T}root access${UI_N}\n"
ui_hr2
ui_kv "IP" "${VPS_IP:-unknown}"
ui_kv "Username" "root"
ui_kv "Password" "$PW"
ui_kv "Port" "${PORTS[*]}"
ui_hr2
unset UI_HRW
echo
ui_note "Save this data before closing."
echo
read -n 1 -s -r -p "$(printf "${UI_T}›${UI_N} ${UI_D}press any key to exit${UI_N}")" </dev/tty
echo
